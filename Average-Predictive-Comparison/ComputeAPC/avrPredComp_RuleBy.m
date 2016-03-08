% This function computes the average predictive comparison between rules at
% a particular level of another covariate (the "by" variable).
% For example, we could compute the average difference between rules when
% an error has been committed in the previous trial or when the monkey
% saccades to the left.
function [avpred] = avrPredComp_RuleBy(sessionName, apcParams, covInfo)
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

% Size of Design Matrix
numData = size(spikeCov(covNames{1}), 1);

% Simulate from posterior
for neuron_ind = 1:numNeurons,
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

% Find the covariate index for the rule variable, the variable to be held
% constant and the other inputs
otherNames = covNames(ismember(covNames, model.terms) ...
    & ~ismember(covNames, apcParams.factorOfInterest) ...
    & ~ismember(covNames, 'Rule'));

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

byData = spikeCov(apcParams.factorOfInterest);
byIsCategorical = covInfo(apcParams.factorOfInterest).isCategorical;
if byIsCategorical,
    byLevels = covInfo(apcParams.factorOfInterest).levels;
    byData = dummyvar(byData);
else
    % Assume normalized continuous variable
    byLevels = [strcat('-', covInfo(apcParams.factorOfInterest).levels), covInfo(apcParams.factorOfInterest).levels];
    byLevelsID = [-1 1];
end

trialTime = grp2idx(gam.trialTime);
origCov = spikeCov(apcParams.factorOfInterest);

% Loop over each level of the by variable
for by_id = 1:length(byLevels),
    
    %% Figure out the matrix of other inputs
    if any(ismember({'Previous Error History', 'Congruency History'}, apcParams.factorOfInterest)),
        if mod(by_id, 2) == 1,
            history = byData(:, ~ismember(1:length(byLevels), by_id:by_id+1));
        else
            history = byData(:, ~ismember(1:length(byLevels), by_id-1:by_id));
        end
    else
        history = [];
    end
    
    other_inputs = [otherData{:} history];
    if ~isempty(other_inputs),
        other_inputs = other_inputs(sample_ind, :);
    end
    %% Compute covariance matrix used for Mahalanobis distances:
    % Find weights
    other_isCategorical = [isCategorical{:} true(1, size(history ,2))];
    if apcParams.isWeighted,
        [summedWeights] = apc_weights(other_inputs, other_isCategorical);
    else
        summedWeights = [];
    end
    if isempty(summedWeights),
        summedWeights = ones(numData, 1);
    end
    den = accumarray(trialTime, summedWeights);
    %% Compute the difference between the two rules at a specified level of the factor of interest
    
    % Set all trials to the orientation rule
    cov = spikeCov('Rule');
    cov(:) = find(ismember(covInfo('Rule').levels, 'Orientation'));
    spikeCov('Rule') = cov;
    
    % Set all trials to one of the levels of the factor of interest
    factorCov = origCov;
    if any(ismember({'Previous Error History', 'Congruency History'}, apcParams.factorOfInterest)),
        factorCov(:, round(by_id/2)) = (mod(by_id, 2) == 0) + 1;
    elseif byIsCategorical
        factorCov(:) = by_id;
    else
        factorCov(:) = byLevelsID(by_id);
    end
    spikeCov(apcParams.factorOfInterest) = factorCov;
    
    orientationDesignMatrix = gamModelMatrix(gamParams.regressionModel_str, spikeCov, covInfo, 'level_reference', gam.level_reference);
    orientationDesignMatrix = orientationDesignMatrix(sample_ind, :) * gam.constraints';
    
    % Set all trials to the color rule
    cov(:) = find(ismember(covInfo('Rule').levels, 'Color'));
    spikeCov('Rule') = cov;
    
    colorDesignMatrix = gamModelMatrix(gamParams.regressionModel_str, spikeCov, covInfo, 'level_reference', gam.level_reference);
    colorDesignMatrix = colorDesignMatrix(sample_ind, :) * gam.constraints';
    
    for neuron_ind = 1:numNeurons,
        colorEst = exp(colorDesignMatrix * squeeze(parEst(:, neuron_ind, :))) * 1000;
        orientationEst = exp(orientationDesignMatrix * squeeze(parEst(:, neuron_ind, :))) * 1000;
        
        parfor sim_ind = 1:apcParams.numSim,
            diffEst = bsxfun(@times, summedWeights, orientationEst(:, sim_ind) - colorEst(:, sim_ind));
            sumEst = orientationEst(:, sim_ind) + colorEst(:, sim_ind);
            
            num = accumarray(trialTime, diffEst);
            absNum = accumarray(trialTime, abs(diffEst));
            normNum = accumarray(trialTime, diffEst ./ sumEst);
            
            apc(:, sim_ind) = num ./ den;
            abs_apc(:, sim_ind) = absNum ./ den;
            norm_apc(:, sim_ind) = normNum ./ den;
        end
        avpred(neuron_ind).apc(by_id, :, :) = apc;
        avpred(neuron_ind).abs_apc(by_id, :, :) = abs_apc;
        avpred(neuron_ind).norm_apc(by_id, :, :) = norm_apc;
    end
    
end

[avpred.numSamples] = deal(apcParams.numSamples);
[avpred.numSim] = deal(apcParams.numSim);
[avpred.sessionName] = deal(sessionName);
[avpred.regressionModel_str] = deal(apcParams.regressionModel_str);
[avpred.wireNumber] = deal(neuron.wireNumber);
[avpred.unitNumber] = deal(neuron.unitNumber);
[avpred.brainArea] = deal(neuron.brainArea);
[avpred.monkeyNames] = deal(neuron.monkeyName);
baseline = num2cell(exp(parEst(1, :, :)) * 1000, 3);
[avpred.baselineFiringRate] = deal(baseline{:});
[avpred.byLevels] = deal(byLevels);
[avpred.trialTime] = deal(unique(gam.trialTime));

saveFolder = sprintf('%s/Processed Data/%s/Models/%s/APC/RuleBy_%s/', main_dir, apcParams.timePeriod, modelList(apcParams.regressionModel_str), apcParams.factorOfInterest);
if ~exist(saveFolder, 'dir'),
    mkdir(saveFolder);
end
save_file_name = sprintf('%s/%s_APC.mat', saveFolder, sessionName);
save(save_file_name, 'avpred');
end