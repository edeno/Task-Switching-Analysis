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
% Load fitting data
GAMfit_name = sprintf('%s/Processed Data/%s/Models/%s/%s_GAMfit.mat', main_dir, apcParams.timePeriod, modelList(apcParams.regressionModel_str), sessionName);
load(GAMfit_name, 'gam', 'gamParams', 'neurons', 'stats', 'numNeurons', 'SpikeCov');

% Get the names of the covariates for the current model
model = modelFormula_parse(gamParams.regressionModel_str);
covNames = SpikeCov.keys;

% Size of Design Matrix
numPredictors = length(neurons(1).parEst);
numData = size(SpikeCov(covNames{1}).data, 1);

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

% Find the covariate index for the rule variable, the variable to be held
% constant and the other inputs
otherNames = covNames(ismember(covNames, model.terms) ...
    & ~ismember(covNames, apcParams.factorOfInterest) ...
    & ~ismember(covNames, 'Rule'));

if ~isempty(otherNames),
    otherData = cellfun(@(x) SpikeCov(x).data, otherNames, 'UniformOutput', false);
    
    isCategorical = cell2mat(cellfun(@(x) covInfo(x).isCategorical, otherNames, 'UniformOutput', false));
    isCategorical(ismember(otherNames, {'Rule Repetition', 'Previous Error History Indicator'})) = false;
    
    otherData(isCategorical) = cellfun(@(x) dummyvar(x), otherData(isCategorical), 'UniformOutput', false);
    
    isCategorical = cellfun(@(categorical, data) repmat(categorical, [1 size(data, 2)]), num2cell(isCategorical), otherData, 'UniformOutput', false);
else
    isCategorical = {};
    otherData = {};
end

byData = SpikeCov(apcParams.factorOfInterest).data;
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
        [summed_weights] = apc_weights(other_inputs, other_isCategorical);
    else
        summed_weights = [];
    end
    if isempty(summed_weights),
        summed_weights = ones(numData, 1);
    end
    den = accumarray(trialTime, summed_weights);
    %% Compute the difference between the two rules at a specified level of the factor of interest
    
    % Set all trials to the orientation rule
    orientationCov = SpikeCov;
    cov.data = SpikeCov('Rule').data;
    cov.data(:) = find(ismember(covInfo('Rule').levels, 'Orientation'));
    orientationCov('Rule') = cov;
    
    % Set all trials to one of the levels of the factor of interest
    cov.data = SpikeCov(apcParams.factorOfInterest).data;
    if any(ismember({'Previous Error History', 'Congruency History'}, apcParams.factorOfInterest)),
        cov.data(:, round(by_id/2)) = (mod(by_id, 2) == 0) + 1;
    elseif byIsCategorical
        cov.data(:) = by_id;
    else
        cov.data(:) = byLevelsID(by_id);
    end
    orientationCov(apcParams.factorOfInterest) = cov;
    
    orientationDesignMatrix = gamModelMatrix(gamParams.regressionModel_str, orientationCov, covInfo, 'level_reference', gam.level_reference);
    orientationDesignMatrix = orientationDesignMatrix(sample_ind, :) * gam.constraints';
    
    % Set all trials to the color rule
    colorCov = SpikeCov;
    cov.data = SpikeCov('Rule').data;
    cov.data(:) = find(ismember(covInfo('Rule').levels, 'Color'));
    colorCov('Rule') = cov;
    
    % Set all trials to one of the levels of the factor of interest
    cov.data = SpikeCov(apcParams.factorOfInterest).data;
    if any(ismember({'Previous Error History', 'Congruency History'}, apcParams.factorOfInterest)),
        cov.data(:, round(by_id/2)) = (mod(by_id, 2) == 0) + 1;
    elseif byIsCategorical
        cov.data(:) = by_id;
    else
        cov.data(:) = byLevelsID(by_id);
    end
    colorCov(apcParams.factorOfInterest) = cov;
    colorDesignMatrix = gamModelMatrix(gamParams.regressionModel_str, colorCov, covInfo, 'level_reference', gam.level_reference);
    colorDesignMatrix = colorDesignMatrix(sample_ind, :) * gam.constraints';
    
    for neuron_ind = 1:numNeurons,
        colorEst = exp(colorDesignMatrix * squeeze(parEst(:, neuron_ind, :))) * 1000;
        orientationEst = exp(orientationDesignMatrix * squeeze(parEst(:, neuron_ind, :))) * 1000;
        
        parfor sim_ind = 1:apcParams.numSim,
            diffEst = orientationEst(:, sim_ind) - colorEst(:, sim_ind);
            sumEst = orientationEst(:, sim_ind) + colorEst(:, sim_ind);
            num = bsxfun(@times, summed_weights, diffEst);
            
            norm_num = accumarray(trialTime, num ./ sumEst);
            num = accumarray(trialTime, num);
            abs_num = abs(num);
            
            apc(:, sim_ind) = num ./ den;
            abs_apc(:, sim_ind) = abs_num ./ den;
            norm_apc(:, sim_ind) = norm_num ./ den;
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
[avpred.wireNumber] = deal(neurons.wireNumber);
[avpred.unitNumber] = deal(neurons.unitNumber);
[avpred.brainArea] = deal(neurons.brainArea);
[avpred.monkeyNames] = deal(neurons.monkeyName);
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