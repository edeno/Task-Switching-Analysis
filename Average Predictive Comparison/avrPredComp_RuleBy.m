% This function computes the average predictive comparison between rules at
% a particular level of another covariate (the "by" variable).
% For example, we could compute the average difference between rules when
% an error has been committed in the previous trial or when the monkey
% saccades to the left.
function [avpred] = avrPredComp_RuleBy(session_name, timePeriod, model_name, by_name, numSim, numSamples, save_folder, main_dir)

% Load covariate fit and model fit information
load([main_dir, '/paramSet.mat'], 'data_info');
GLMCov_name = sprintf('%s/%s/GLMCov/%s_GLMCov.mat', data_info.processed_dir, timePeriod, session_name);
load(GLMCov_name, 'GLMCov', 'isCorrect', 'spikes', 'trial_id', 'trial_time')
GAMfit_name = sprintf('%s/%s/Models/%s/%s_GAMfit.mat', data_info.processed_dir, timePeriod, model_name, session_name);
load(GAMfit_name, 'gam', 'gamParams', 'neurons', 'numNeurons');

if ~gamParams.includeIncorrect
    spikes(~isCorrect, :) = [];
    trial_time(~isCorrect) = [];
    trial_id(~isCorrect) = [];
    for GLMCov_ind = 1:length(GLMCov),
        GLMCov(GLMCov_ind).data(~isCorrect, :) = [];
    end
end

if ~gamParams.includeTimeBeforeZero,
    isBeforeZero = trial_time < 0;
    spikes(isBeforeZero, :) = [];
    trial_time(isBeforeZero) = [];
    trial_id(isBeforeZero) = [];
    for GLMCov_ind = 1:length(GLMCov),
        GLMCov(GLMCov_ind).data(isBeforeZero, :) = [];
    end
end

% Since we are not considering time, inputs only vary by trial
[~, unique_trial_ind, ~] = unique(trial_id);

for GLMCov_ind = 1:length(GLMCov),
    GLMCov(GLMCov_ind).data = GLMCov(GLMCov_ind).data(unique_trial_ind, :);
end
spikes = spikes(unique_trial_ind, :);

% Get the names of the covariates for the current model
cov_names = strtrim(regexp(regexp(gam.model_str, '+', 'split'), '*', 'split'));
unique_cov_names = unique([cov_names{:}]);

% Size of Design Matrix
numPredictors = length(neurons(1).par_est);
numData = size(spikes, 1);

% Simulate from posterior
par_est = nan(numPredictors, numNeurons, numSim);

for neuron_ind = 1:numNeurons,
    par_est(:, neuron_ind, :) = mvnrnd(neurons(neuron_ind).par_est, neurons(neuron_ind).stats.covb, numSim)';
end

% Cut down on the number of data points by sampling
if numData <= numSamples,
    sample_ind = 1:numData;
else
    sample_ind = randi([1, numData], [1 numSamples]);
    numData = numSamples;
end

% Find the covariate index for the rule variable, the variable to be held
% constant and the other inputs
rule_ind = ismember({GLMCov.name}, 'Rule');
by_ind = ismember({GLMCov.name}, by_name);
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
    if any(ismember({'Previous Error History', 'Congruency History'}, by_name)),
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
    [summed_weights] = apc_weights(other_inputs, other_isCategorical);
    
    %% Compute the difference between the two rules
    
    orientationCov = GLMCov;
    orientationCov(rule_ind).data(:) = find(ismember(orientationCov(rule_ind).levels, 'Orientation'));
    if any(ismember({'Previous Error History', 'Congruency History'}, by_name)),
        orientationCov(by_ind).data(:, round(by_id/2)) = (mod(by_id, 2) == 0) + 1;
    elseif by_isCategorical
        orientationCov(by_ind).data(:) = by_id;
    else
        orientationCov(by_ind).data(:) = by_levels_id(by_id);
    end
    
    [orientation_design] = gamModelMatrix(gamParams.regressionModel_str, orientationCov, spikes(:,1));
    orientation_design = orientation_design(sample_ind, :);
    
    orientation_est = nan(numData, numNeurons, numSim);
    for neuron_ind = 1:numNeurons,
        orientation_est(:, neuron_ind, :) = exp(orientation_design*squeeze(par_est(:, neuron_ind, :)))*1000;
    end
    
    colorCov = GLMCov;
    colorCov(rule_ind).data(:) = find(ismember(colorCov(rule_ind).levels, 'Color'));
    if any(ismember({'Previous Error History', 'Congruency History'}, by_name)),
        colorCov(by_ind).data(:, round(by_id/2)) = (mod(by_id, 2) == 0) + 1;
    elseif by_isCategorical
        colorCov(by_ind).data(:) = by_id;
    else
        colorCov(by_ind).data(:) = by_levels_id(by_id);
    end
    [color_design] = gamModelMatrix(gamParams.regressionModel_str, colorCov, spikes(:,1));
    color_design = color_design(sample_ind, :);
    
    color_est = nan(numData, numNeurons, numSim);
    for neuron_ind = 1:numNeurons,
        color_est(:, neuron_ind, :) = exp(color_design*squeeze(par_est(:, neuron_ind, :)))*1000;
    end
    
    rule_diff_est = orientation_est - color_est;
    rule_sum_est = orientation_est + color_est;
    
    num = nansum(bsxfun(@times, summed_weights, rule_diff_est));
    abs_num = nansum(bsxfun(@times, summed_weights, abs(rule_diff_est)));
    norm_num = nansum(bsxfun(@times, summed_weights, rule_diff_est./rule_sum_est));
    
    den = nansum(summed_weights);
    
    apc = num./den;
    abs_apc = abs_num./den;
    norm_apc = norm_num./den;
    
    for neuron_ind = 1:numNeurons,
        avpred(neuron_ind).apc(by_id,:) = squeeze(apc(:, neuron_ind, :));
        avpred(neuron_ind).abs_apc(by_id,:) = squeeze(abs_apc(:, neuron_ind, :));
        avpred(neuron_ind).norm_apc(by_id,:) = squeeze(norm_apc(:, neuron_ind, :));
    end
    
end

[avpred.numSamples] = deal(numSamples);
[avpred.numSim] = deal(numSim);
[avpred.session_name] = deal(session_name);
[avpred.model_name] = deal(model_name);
[avpred.wire_number] = deal(neurons.wire_number);
[avpred.unit_number] = deal(neurons.unit_number);
[avpred.pfc] = deal(neurons.pfc);
[avpred.monkey] = deal(neurons.monkey);
baseline = num2cell(exp(par_est(1, :, :))*1000, 3);
[avpred.baseline_firing] = deal(baseline{:});
[avpred.by_levels] = deal(by_levels);

save_file_name = sprintf('%s/%s_APC.mat', save_folder, session_name);
[~, hostname] = system('hostname');
hostname = strcat(hostname);
if strcmp(hostname, 'millerlab'),
    saveMillerlab('edeno', save_file_name, 'avpred');
else
    save(save_file_name, 'avpred');
end

end