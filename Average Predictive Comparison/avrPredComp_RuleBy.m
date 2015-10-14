% This function computes the average predictive comparison between rules at
% a particular level of another covariate (the "by" variable).
% For example, we could compute the average difference between rules when
% an error has been committed in the previous trial or when the monkey
% saccades to the left.
function [avpred] = avrPredComp_RuleBy(session_name, apcParams)


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

% Find the covariate index for the rule variable, the variable to be held
% constant and the other inputs
rule_ind = ismember({GLMCov.name}, 'Rule');
by_ind = ismember({GLMCov.name}, apcParams.type);
other_ind = ismember({GLMCov.name}, unique_cov_names) & (~rule_ind | ~by_ind);

by_data = GLMCov(by_ind).data;
other_data = {GLMCov(other_ind).data};

isCategorical = [GLMCov(other_ind).isCategorical] & ~ismember({GLMCov(other_ind).name}, {'Switch History', 'Previous Error History Indicator'});

other_data(isCategorical) = cellfun(@(x) dummyvar(x), other_data(isCategorical), 'UniformOutput', false);

isCategorical = cellfun(@(categorical, data) repmat(categorical, [1 size(data,2)]), num2cell(isCategorical), other_data, 'UniformOutput', false);

by_isCategorical = GLMCov(by_ind).isCategorical;
if by_isCategorical,
    by_levels = GLMCov(by_ind).levels;
    by_data = dummyvar(by_data);
else
    by_levels = [strcat('-',GLMCov(by_ind).levels), GLMCov(by_ind).levels];
    by_levels_id = [-1 1];
end

% Loop over each level of the by variable
for by_id = 1:length(by_levels),
    
    %% Figure out the matrix of other inputs
    if any(ismember({'Previous Error History', 'Congruency History'}, apcParams.type)),
        if mod(by_id, 2) == 1,
            history = by_data(:, ~ismember(1:length(by_levels), by_id:by_id+1));
        else
            history = by_data(:, ~ismember(1:length(by_levels), by_id-1:by_id));
        end
    else
        history = [];
    end
    
    other_inputs = [other_data{:} history];
    other_inputs = other_inputs(sample_ind, :);
    
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
    %% Compute the difference between the two rules
    orientationCov = GLMCov;
    orientationCov(rule_ind).data(:) = find(ismember(orientationCov(rule_ind).levels, 'Orientation'));
    if any(ismember({'Previous Error History', 'Congruency History'}, apcParams.type)),
        orientationCov(by_ind).data(:, round(by_id/2)) = (mod(by_id, 2) == 0) + 1;
    elseif by_isCategorical
        orientationCov(by_ind).data(:) = by_id;
    else
        orientationCov(by_ind).data(:) = by_levels_id(by_id);
    end
    
    orientationDesignMatrix = gamModelMatrix(gamParams.regressionModel_str, orientationCov);
    orientationDesignMatrix = orientationDesignMatrix(sample_ind, :) * gam.constraints';
    
    colorCov = GLMCov;
    colorCov(rule_ind).data(:) = find(ismember(colorCov(rule_ind).levels, 'Color'));
    if any(ismember({'Previous Error History', 'Congruency History'}, apcParams.type)),
        colorCov(by_ind).data(:, round(by_id/2)) = (mod(by_id, 2) == 0) + 1;
    elseif by_isCategorical
        colorCov(by_ind).data(:) = by_id;
    else
        colorCov(by_ind).data(:) = by_levels_id(by_id);
    end
    colorDesignMatrix = gamModelMatrix(gamParams.regressionModel_str, colorCov);
    colorDesignMatrix = colorDesignMatrix(sample_ind, :) * gam.constraints';
    
    for neuron_ind = 1:numNeurons,
        colorEst = exp(colorDesignMatrix * squeeze(par_est(:, neuron_ind, :))) * 1000;
        orientationEst = exp(orientationDesignMatrix * squeeze(par_est(:, neuron_ind, :))) * 1000;
        
        parfor sim_ind = 1:apcParams.numSim,
            diffEst = orientationEst(:, sim_ind) - colorEst(:, sim_ind);
            sumEst = orientationEst(:, sim_ind) + colorEst(:, sim_ind);
            num = bsxfun(@times, summed_weights, diffEst);
            
            norm_num = accumarray(trial_time, num ./ sumEst);
            num = accumarray(trial_time, num);
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

[avpred.numSamples] = deal(numSamples);
[avpred.numSim] = deal(numSim);
[avpred.session_name] = deal(session_name);
[avpred.regressionModel_str] = deal(apcParams.regressionModel_str);
[avpred.wire_number] = deal(neurons.wire_number);
[avpred.unit_number] = deal(neurons.unit_number);
[avpred.brainArea] = deal(neurons.brainArea);
[avpred.monkey] = deal(neurons.monkey);
baseline = num2cell(exp(par_est(1, :, :))*1000, 3);
[avpred.baseline_firing] = deal(baseline{:});
[avpred.by_levels] = deal(by_levels);
[avpred.trial_time] = deal(unique(gam.trial_time));
% [avpred.numTrialsByLevel] = deal(gam.numTrialsByLevel);

saveFolder = sprintf('%s/Processed Data/%s/Models/%s/APC/RuleBy_%s/', main_dir, apcParams.timePeriod, modelList(apcParams.regressionModel_str), apcParams.type);
if ~exist(saveFolder, 'dir'),
    mkdir(saveFolder);
end
save_file_name = sprintf('%s/%s_APC.mat', saveFolder, session_name);
save(save_file_name, 'avpred');

end