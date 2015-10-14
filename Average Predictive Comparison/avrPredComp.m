% This function computes the average predictive comparison between rules at
% a particular level of another covariate (the "by" variable).
% For example, we could compute the average difference between rules when
% an error has been committed in the previous trial or when the monkey
% saccades to the left.
function [avpred] = avrPredComp(session_name, apcParams)

%% Load covariate fit and model fit information
main_dir = getWorkingDir();
% Get GLM Covariates
GLMCov_name = sprintf('%s/Processed Data/%s/GLMCov/%s_GLMCov.mat', main_dir, apcParams.timePeriod, session_name);
load(GLMCov_name, 'GLMCov', 'isCorrect', 'isAttempted', 'spikes', 'trial_time', 'trial_id')
% Load model list
modelList_name = sprintf('%s/Processed Data/%s/Models/modelList.mat', main_dir, apcParams.timePeriod);
load(modelList_name, 'modelList');
% Load fitting data
GAMfit_name = sprintf('%s/Processed Data/%s/Models/%s/%s_GAMfit.mat', main_dir, apcParams.timePeriod, modelList(apcParams.regressionModel_str), session_name);
load(GAMfit_name, 'gam', 'gamParams', 'neurons', 'stats', 'numNeurons');

%% Make GLM covariate data like the fit model
if ~gamParams.includeIncorrect
    spikes(~isCorrect, :) = [];
    trial_time(~isCorrect) = [];
    trial_id(~isCorrect) = [];
    for GLMCov_ind = 1:length(GLMCov),
        if isempty( GLMCov(GLMCov_ind).data), continue; end
        GLMCov(GLMCov_ind).data(~isCorrect, :) = [];
    end
end

if ~gamParams.includeTimeBeforeZero,
    isBeforeZero = trial_time < 0;
    spikes(isBeforeZero, :) = [];
    trial_time(isBeforeZero) = [];
    trial_id(isBeforeZero) = [];
    for GLMCov_ind = 1:length(GLMCov),
        if isempty( GLMCov(GLMCov_ind).data), continue; end
        GLMCov(GLMCov_ind).data(isBeforeZero, :) = [];
    end
end

if ~gamParams.includeFixationBreaks
    spikes(~isAttempted, :) = [];
    trial_time(~isAttempted) = [];
    trial_id(~isAttempted) = [];
    for GLMCov_ind = 1:length(GLMCov),
        if isempty( GLMCov(GLMCov_ind).data), continue; end
        GLMCov(GLMCov_ind).data(~isAttempted, :) = [];
    end
end

% Get the names of the covariates for the current model
model = modelFormula_parse(gamParams.regressionModel_str);

% Size of Design Matrix
numPredictors = length(neurons(1).par_est);
numData = size(GLMCov(1).data, 1);

% Simulate from posterior
par_est = nan(numPredictors, numNeurons, apcParams.numSim);

for neuron_ind = 1:numNeurons,
    par_est(:, neuron_ind, :) = mvnrnd(neurons(neuron_ind).par_est, stats(neuron_ind).covb, apcParams.numSim)';
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
factor_ind = ismember({GLMCov.name}, apcParams.type);
other_ind = ismember({GLMCov.name}, model.terms) & (~factor_ind);

if GLMCov(factor_ind).isCategorical,
    levels = GLMCov(factor_ind).levels;
else
    % Assume normalized continuous variable
    levels = [strcat('-',GLMCov(factor_ind).levels), GLMCov(factor_ind).levels];
    levels_id = [-1 1];
end

factor_data = GLMCov(factor_ind).data;
other_data = {GLMCov(other_ind).data};

isCategorical = [GLMCov(other_ind).isCategorical] & ~ismember({GLMCov(other_ind).name}, {'Rule Repetition', 'Previous Error History Indicator'});

other_data(isCategorical) = cellfun(@(x) dummyvar(x), other_data(isCategorical), 'UniformOutput', false);

isCategorical = cellfun(@(categorical, data) repmat(categorical, [1 size(data,2)]), num2cell(isCategorical), other_data, 'UniformOutput', false);

numHistoryFactors = size(factor_data, 2);

% If the factor is a history variable, then we need to loop over each
% history variable. If the factor is an ordered categorical variable with
% more than two levels, we need to calculate the different between all the
% other levels and the last level. Currently no support for unordered
% categorical variables that aren't binary.
counter_idx = 1;
trial_time = grp2idx(trial_time);

for history_ind = 1:numHistoryFactors,
    
    %% Figure out the matrix of other inputs
    if any(ismember({'Previous Error History', 'Congruency History'}, apcParams.type)),
        history = factor_data(:, ~ismember(1:numHistoryFactors, history_ind));
        history = dummyvar(history);
        curLevels = reshape(levels, 2, numHistoryFactors);
    else
        history = [];
        curLevels = levels';
    end
    
    other_inputs = [other_data{:} history];
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
    den = accumarray(trial_time, summed_weights);
    %% Compute the difference the lowest level and all other levels (doesn't work for unordered categorical variables)
    if GLMCov(factor_ind).isCategorical,
        level_data = unique(factor_data(:, ismember(history_ind, 1:numHistoryFactors)));
        level_data(isnan(level_data)) = [];
    else
        level_data = [-1 1];
    end
    
    % Compute the firing rate holding thne last level constant (only need to do this once)
    baselineCov = GLMCov;
    baselineLevel_ind = ismember(baselineCov(factor_ind).levels, baselineCov(factor_ind).baselineLevel);
    baselineCov(factor_ind).data(:, history_ind) = level_data(baselineLevel_ind);
    baselineDesignMatrix = gamModelMatrix(gamParams.regressionModel_str, baselineCov, 'level_reference', gam.level_reference);
    baselineDesignMatrix = baselineDesignMatrix(sample_ind, :) * gam.constraints';
    baselineLevelEst = nan(numData, numNeurons, apcParams.numSim);
    baselineLevelName = curLevels{baselineLevel_ind, history_ind};
    for neuron_ind = 1:numNeurons,
        baselineLevelEst(:, neuron_ind, :) = exp(baselineDesignMatrix * squeeze(par_est(:, neuron_ind, :))) * 1000;
    end
    
    % Number of levels to iterate over.
    levelID = find(~ismember(baselineCov(factor_ind).levels, baselineCov(factor_ind).baselineLevel));
    numLevels = length(levelID);
    
    for level_ind = 1:numLevels,
        curLevelCov = GLMCov;
        curLevelCov(factor_ind).data(:, history_ind) = level_data(levelID(level_ind));
        curLevelDesignMatrix = gamModelMatrix(gamParams.regressionModel_str, curLevelCov, 'level_reference', gam.level_reference);
        curLevelDesignMatrix = curLevelDesignMatrix(sample_ind, :) * gam.constraints';
        curLevelName = curLevels{levelID(level_ind), history_ind};
        for neuron_ind = 1:numNeurons,
            parfor sim_ind = 1:apcParams.numSim,
                curLevelEst = exp(curLevelDesignMatrix * squeeze(par_est(:, neuron_ind, sim_ind))) * 1000;
                diffEst = curLevelEst - squeeze(baselineLevelEst(:, neuron_ind, sim_ind));
                sumEst = curLevelEst + squeeze(baselineLevelEst(:, neuron_ind, sim_ind));
                num = bsxfun(@times, summed_weights, diffEst);
                
                norm_num = accumarray(trial_time, num ./ sumEst);
                num = accumarray(trial_time, num);
                abs_num = abs(num);
                
                apc(:, sim_ind) = num ./ den;
                abs_apc(:, sim_ind) = abs_num ./ den;
                norm_apc(:, sim_ind) = norm_num ./ den;
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
[avpred.session_name] = deal(session_name);
[avpred.regressionModel_str] = deal(apcParams.regressionModel_str);
[avpred.wire_number] = deal(neurons.wire_number);
[avpred.unit_number] = deal(neurons.unit_number);
[avpred.brainArea] = deal(neurons.brainArea);
[avpred.monkey] = deal(neurons.monkey);
baseline = num2cell(exp(par_est(1, :, :)) * 1000, 3);
[avpred.baseline_firing] = deal(baseline{:});
[avpred.levels] = deal(comparisonNames);
[avpred.trial_time] = deal(unique(gam.trial_time));
% [avpred.numTrialsByLevel] = deal(gam.numTrialsByLevel);

saveFolder = sprintf('%s/Processed Data/%s/Models/%s/APC/%s/', main_dir, apcParams.timePeriod, modelList(apcParams.regressionModel_str), apcParams.type);
if ~exist(saveFolder, 'dir'),
    mkdir(saveFolder);
end
save_file_name = sprintf('%s/%s_APC.mat', saveFolder, session_name);
save(save_file_name, 'avpred');

end