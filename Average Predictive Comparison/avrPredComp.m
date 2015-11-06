% This function computes the average predictive comparison between rules at
% a particular level of another covariate (the "by" variable).
% For example, we could compute the average difference between rules when
% an error has been committed in the previous trial or when the monkey
% saccades to the left.
function [avpred] = avrPredComp(sessionName, apcParams, covInfo)

%% Load covariate fit and model fit information
main_dir = getWorkingDir();
modelList_name = sprintf('%s/Processed Data/%s/Models/modelList.mat', main_dir, apcParams.timePeriod);
load(modelList_name, 'modelList');
% Load fitting data
GAMfit_name = sprintf('%s/Processed Data/%s/Models/%s/%s_GAMfit.mat', main_dir, apcParams.timePeriod, modelList(apcParams.regressionModel_str), sessionName);
load(GAMfit_name, 'gam', 'gamParams', 'neurons', 'stats', 'numNeurons', 'spikeCov');

% Get the names of the covariates for the current model
model = modelFormulaParse(gamParams.regressionModel_str);
covNames = spikeCov.keys;

% Size of Design Matrix
numPredictors = length(neurons(1).parEst);
numData = size(spikeCov(covNames{1}), 1);

% Simulate from posterior
parEst = nan(numPredictors, numNeurons, apcParams.numSim);

for neuron_ind = 1:numNeurons,
    parEst(:, neuron_ind, :) = mvnrnd(neurons(neuron_ind).parEst, stats(neuron_ind).covb, apcParams.numSim)';
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
origCov = spikeCov(apcParams.factorOfInterest);
baselineLevel_ind = ismember(covInfo(apcParams.factorOfInterest).levels, covInfo(apcParams.factorOfInterest).baselineLevel);

for history_ind = 1:numHistoryFactors,
    %% Figure out the matrix of other inputs
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
        for neuron_ind = 1:numNeurons,
            curLevelEst = exp(curLevelDesignMatrix * squeeze(parEst(:, neuron_ind, :))) * 1000;
            baselineLevelEst = exp(baselineDesignMatrix * squeeze(parEst(:, neuron_ind, :))) * 1000;
            parfor sim_ind = 1:apcParams.numSim,
                diffEst = bsxfun(@times, summedWeights, curLevelEst(:, sim_ind) - baselineLevelEst(:, sim_ind));
                sumEst = curLevelEst(:, sim_ind) + baselineLevelEst(:, sim_ind);
                
                apc(:, sim_ind) = accumarray(trialTime, diffEst) ./ den;
                abs_apc(:, sim_ind) = accumarray(trialTime, abs(diffEst)) ./ den;
                norm_apc(:, sim_ind) = accumarray(trialTime, diffEst ./ sumEst) ./ den;
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
[avpred.wireNumber] = deal(neurons.wireNumber);
[avpred.unitNumber] = deal(neurons.unitNumber);
[avpred.brainArea] = deal(neurons.brainArea);
[avpred.monkeyNames] = deal(neurons.monkeyName);
baseline = num2cell(exp(parEst(1, :, :)) * 1000, 3);
[avpred.baselineFiringRate] = deal(baseline{:});
[avpred.comparisonNames] = deal(comparisonNames);
[avpred.trialTime] = deal(unique(gam.trialTime));

saveFolder = sprintf('%s/Processed Data/%s/Models/%s/APC/%s/', main_dir, apcParams.timePeriod, modelList(apcParams.regressionModel_str), apcParams.factorOfInterest);
if ~exist(saveFolder, 'dir'),
    mkdir(saveFolder);
end
save_file_name = sprintf('%s/%s_APC.mat', saveFolder, sessionName);
save(save_file_name, 'avpred');

end