% This function computes the average predictive comparison between rules at
% a particular level of another covariate (the "by" variable).
% For example, we could compute the average difference between rules when
% an error has been committed in the previous trial or when the monkey
% saccades to the left.
function [avpred] = avrPredComp(sessionName, apcParams, covInfo)
%% Log parameters
fprintf('\n------------------------\n');
fprintf('\nSession: %s\n', sessionName);
fprintf('\nDate: %s\n \n', datestr(now));
fprintf('\nAPC Parameters\n');
fprintf('\t regressionModel_str: %s\n', apcParams.regressionModel_str);
fprintf('\t timePeriod: %s\n', apcParams.timePeriod);
fprintf('\t factorOfInterest: %s\n', apcParams.factorOfInterest);
fprintf('\t numSim: %d\n', apcParams.numSim);
fprintf('\t numSamples: %d\n', apcParams.numSamples);
fprintf('\t isWeighted: %d\n', apcParams.isWeighted);
fprintf('\t overwrite: %d\n', apcParams.overwrite);
%% Load covariate fit and model fit information
main_dir = getWorkingDir();
modelList_name = sprintf('%s/Processed Data/%s/Models/modelList.mat', main_dir, apcParams.timePeriod);
load(modelList_name, 'modelList');

saveFolder = sprintf('%s/Processed Data/%s/Models/%s/APC/%s/', main_dir, apcParams.timePeriod, modelList(apcParams.regressionModel_str), apcParams.factorOfInterest);
if ~exist(saveFolder, 'dir'),
    mkdir(saveFolder);
end
saveFileName = sprintf('%s/%s_APC.mat', saveFolder, sessionName);
if exist(saveFileName, 'file') && ~apcParams.overwrite,
    fprintf('/nFile already exists...exiting/n');
    return;
end
% Load fitting data
modelDir = sprintf('%s/Processed Data/%s/Models/%s/',  main_dir, apcParams.timePeriod, modelList(apcParams.regressionModel_str));
sessionFile = sprintf('%s/%s_GAMfit.mat', modelDir, sessionName);
neuronFiles = dir(sprintf('%s/*_neuron_%s_*_GAMfit.mat', modelDir, sessionName));
neuronFiles = {neuronFiles.name};
load(sessionFile, 'gam', 'gamParams', 'numNeurons', 'spikeCov', 'designMatrix');
assert(length(neuronFiles) == numNeurons);
fprintf('\nNumber of Neurons: %d\n', numNeurons);

% Get the names of the covariates for the current model
model = modelFormulaParse(gamParams.regressionModel_str);
covNames = spikeCov.keys;

numData = size(designMatrix, 1);

% Simulate from posterior
parfor neuron_ind = 1:numNeurons,
    curFile = load(sprintf('%s/%s', modelDir, neuronFiles{neuron_ind}));
    if neuron_ind == 1,
        numPredictors = length(curFile.neuron.parEst);
        parEst = nan(numPredictors, numNeurons, apcParams.numSim);
    end

    avpred(neuron_ind).wireNumber = curFile.neuron.wireNumber;
    avpred(neuron_ind).unitNumber = curFile.neuron.unitNumber;
    avpred(neuron_ind).brainArea = curFile.neuron.brainArea;
    avpred(neuron_ind).monkeyNames = curFile.neuron.monkeyName;
    parEst(:, neuron_ind, :) = mvnrnd(curFile.neuron.parEst, curFile.stat.covb, apcParams.numSim)';
end

% Cut down on the number of data points by sampling
if ~isempty(apcParams.numSamples),
    if numData <= apcParams.numSamples,
        sample_ind = 1:numData;
    else
        sample_ind = sort(randperm(numData, apcParams.numSamples));
        numData = apcParams.numSamples;
    end
else
    sample_ind = 1:numData;
end

% Find the covariate index for the current variable, the variable to be held
% constant and the other inputs
otherNames = covNames(ismember(covNames, model.terms) & ~ismember(covNames, apcParams.factorOfInterest));

factorData = spikeCov(apcParams.factorOfInterest);
if ~isempty(otherNames),
    otherData = cellfun(@(x) spikeCov(x), otherNames, 'UniformOutput', false);

    isCategorical = cell2mat(cellfun(@(x) covInfo(x).isCategorical, otherNames, 'UniformOutput', false));
    isCategorical(ismember(otherNames, {'Rule Repetition', 'Previous Error History Indicator'})) = false;

    otherData(isCategorical) = cellfun(@(x) dummyvar(x), otherData(isCategorical), 'UniformOutput', false);

    isCategorical = cellfun(@(categorical, data) repmat(categorical, [1 size(data, 2)]), num2cell(isCategorical), otherData, 'UniformOutput', false);
else
    isCategorical = {};
    otherData = {};
end

if covInfo(apcParams.factorOfInterest).isCategorical,
    levels = covInfo(apcParams.factorOfInterest).levels;
else
    % Assume normalized continuous variable
    levels = [strcat('-', covInfo(apcParams.factorOfInterest).levels), covInfo(apcParams.factorOfInterest).levels];
    levelsID = [-1 1];
end

numHistoryFactors = size(factorData, 2);

% If the factor is a history variable, then we need to loop over each
% history variable. If the factor is an ordered categorical variable with
% more than two levels, we need to calculate the different between all the
% other levels and the last level. Currently no support for unordered
% categorical variables that aren't binary.
counter_idx = 1;
trialTime = grp2idx(gam.trialTime);
trialTime = trialTime(sample_ind);
origCov = spikeCov(apcParams.factorOfInterest);
baselineLevel_ind = ismember(covInfo(apcParams.factorOfInterest).levels, covInfo(apcParams.factorOfInterest).baselineLevel);

apc = nan(max(trialTime), apcParams.numSim);
abs_apc = nan(max(trialTime), apcParams.numSim);
norm_apc = nan(max(trialTime), apcParams.numSim);

%% Create matlab pool
fprintf('\nCreate matlab pool...\n');
myCluster = parcluster('local');
tempDir = tempname;
mkdir(tempDir);
myCluster.JobStorageLocation = tempDir;  % points to TMPDIR

poolobj = gcp('nocreate'); % If no pool, do not create new one.
if isempty(poolobj)
     parpool(myCluster, min([apcParams.numCores, myCluster.NumWorkers]));
end

for history_ind = 1:numHistoryFactors,
    %% Figure out the matrix of other inputs
    fprintf('\nLoop over history variable #%d...\n', history_ind);
    if ismember(apcParams.factorOfInterest, {'Previous Error History', 'Congruency History'}),
        history = factorData(:, ~ismember(1:numHistoryFactors, history_ind));
        history = dummyvar(history);
        curLevels = reshape(levels, 2, numHistoryFactors);
    else
        history = [];
        curLevels = levels';
    end

    other_inputs = [otherData{:} history];
    if ~isempty(other_inputs),
        other_inputs = other_inputs(sample_ind, :);
    end
    %% Compute covariance matrix used for Mahalanobis distances:
    % Find weights
    fprintf('\nFind weights...\n');
    other_isCategorical = [isCategorical{:} true(1, size(history ,2))];
    if apcParams.isWeighted,
        summedWeights = apc_weights(other_inputs, other_isCategorical);
    else
        summedWeights = [];
    end
    if isempty(summedWeights),
        summedWeights = ones(numData, 1);
    end
    den = accumarray(trialTime, summedWeights);
    %% Compute the difference between the baseline level and all other levels
    if covInfo(apcParams.factorOfInterest).isCategorical,
        levelData = unique(factorData(:, ismember(history_ind, 1:numHistoryFactors)));
        levelData(isnan(levelData)) = [];
    else
        levelData = [-1 1];
    end

    % Compute the firing rate holding thne last level constant (only need to do this once)
    cov = origCov;
    cov(:, history_ind) = levelData(baselineLevel_ind);
    spikeCov(apcParams.factorOfInterest) = cov;
    baselineDesignMatrix = gamModelMatrix(gamParams.regressionModel_str, spikeCov, covInfo, 'level_reference', gam.level_reference);
    baselineDesignMatrix = baselineDesignMatrix(sample_ind, :) * gam.constraints';
    baselineLevelName = curLevels{baselineLevel_ind, history_ind};

    % Number of levels to iterate over.
    levelID = find(~ismember(covInfo(apcParams.factorOfInterest).levels, covInfo(apcParams.factorOfInterest).baselineLevel));
    numLevels = length(levelID);

    for level_ind = 1:numLevels,
        cov(:, history_ind) = levelData(levelID(level_ind));
        spikeCov(apcParams.factorOfInterest) = cov;
        curLevelDesignMatrix = gamModelMatrix(gamParams.regressionModel_str, spikeCov, covInfo, 'level_reference', gam.level_reference);
        curLevelDesignMatrix = curLevelDesignMatrix(sample_ind, :) * gam.constraints';
        curLevelName = curLevels{levelID(level_ind), history_ind};
        %Transfer static assets to each worker only once
        fprintf('\nTransferring static assets to each worker...\n');
        if verLessThan('matlab', '8.6'),
            cLDM = WorkerObjWrapper(curLevelDesignMatrix);
            bDM = WorkerObjWrapper(baselineDesignMatrix);
            tT = WorkerObjWrapper(trialTime);
            d = WorkerObjWrapper(den);
            sW = WorkerObjWrapper(summedWeights);
        else
            cLDM = parallel.pool.Constant(curLevelDesignMatrix);
            bDM = parallel.pool.Constant(baselineDesignMatrix);
            tT = parallel.pool.Constant(trialTime);
            d = parallel.pool.Constant(den);
            sW = parallel.pool.Constant(summedWeights);
        end
%         cLDM.Value = curLevelDesignMatrix;
%         bDM.Value = baselineDesignMatrix;
%         tT.Value = trialTime;
%         d.Value = den;
%         sW.Value = summedWeights;
        fprintf('\nComputing Level: %s...\n', curLevelName);
        for neuron_ind = 1:numNeurons,
            fprintf('\tNeuron: #%d...\n', neuron_ind);
            parfor sim_ind = 1:apcParams.numSim,
                if (mod(sim_ind, 100) == 0)
                    fprintf('\t\tSim #%d...\n', sim_ind);
                end
                curLevelEst = exp(cLDM.Value * squeeze(parEst(:, neuron_ind, sim_ind))) * 1000;
                baselineLevelEst = exp(bDM.Value * squeeze(parEst(:, neuron_ind, sim_ind))) * 1000;
                diffEst = bsxfun(@times, sW.Value, curLevelEst - baselineLevelEst);
                sumEst = curLevelEst + baselineLevelEst;

                apc(:, sim_ind) = accumarray(tT.Value, diffEst, [], [], NaN) ./ d.Value;
                abs_apc(:, sim_ind) = accumarray(tT.Value, abs(diffEst), [], [], NaN) ./ d.Value;
                norm_apc(:, sim_ind) = accumarray(tT.Value, diffEst ./ sumEst, [], [], NaN) ./ d.Value;
            end
            avpred(neuron_ind).apc(counter_idx, :, :) = apc;
            avpred(neuron_ind).abs_apc(counter_idx, :, :) = abs_apc;
            avpred(neuron_ind).norm_apc(counter_idx, :, :) = norm_apc;
        end

        comparisonNames{counter_idx} = sprintf('%s - %s', curLevelName, baselineLevelName);

        counter_idx = counter_idx + 1;
    end

end

[avpred.numSamples] = deal(apcParams.numSamples);
[avpred.numSim] = deal(apcParams.numSim);
[avpred.sessionName] = deal(sessionName);
[avpred.regressionModel_str] = deal(apcParams.regressionModel_str);
baseline = num2cell(exp(parEst(1, :, :)) * 1000, 3);
[avpred.baselineFiringRate] = deal(baseline{:});
[avpred.comparisonNames] = deal(comparisonNames);
[avpred.trialTime] = deal(min(gam.trialTime):max(gam.trialTime(sample_ind)));

fprintf('\nSaving...\n');
save(saveFileName, 'avpred', '-v7.3');
fprintf('\nFinished: %s\n', datestr(now));

end
