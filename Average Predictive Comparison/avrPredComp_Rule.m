% This function computes the average predictive comparison between rules
function [avpred] = avrPredComp_Rule(session_name, timePeriod, model_name, numSim, numSamples, save_folder, main_dir)

% Load covariate fit and model fit information
load([main_dir, '/paramSet.mat'], 'cov_info', 'data_info');
GLMCov_name = sprintf('%s/%s/GLMCov/%s_GLMCov.mat', data_info.processed_dir, timePeriod, session_name);
load(GLMCov_name, 'GLMCov', 'incorrect', 'spikes')
GAMfit_name = sprintf('%s/%s/Models/%s/%s_GAMfit.mat', data_info.processed_dir, timePeriod, model_name, session_name);
load(GAMfit_name, 'gam', 'gamParams', 'neurons', 'designMatrix', 'numNeurons');

% Get the names of the covariates for the current model
cov_names = strtrim(regexp(regexp(gam.model_str, '+', 'split'), '*', 'split'));
unique_cov_names = unique([cov_names{:}]);

% Size of Design Matrix
[numData, numPredictors] = size(designMatrix);

% Simulate from posterior
par_est = nan(numPredictors, numNeurons, numSim);

for neuron_ind = 1:numNeurons,
    par_est(:, neuron_ind, :) = mvnrnd(neurons(neuron_ind).par_est, neurons(neuron_ind).stats.covb, numSim)';
end

% Cut down on the number of data points by sampling
if numData == numSamples,
    sample_ind = 1:numData;
else
    sample_ind = randi([1, numData], [1 numSamples]);
    numData = numSamples;
end

% Find the covariate index for the rule variable and the other inputs
rule_ind = ismember({GLMCov.name}, 'Rule');
other_ind = ismember({GLMCov.name}, unique_cov_names) & (~rule_ind);

other_data = {GLMCov(other_ind).data};

isCategorical = [GLMCov(other_ind).isCategorical] & ~ismember({GLMCov(other_ind).name}, {'Switch History', 'Previous Error History Indicator'});

other_data(isCategorical) = cellfun(@(x) dummyvar(x), other_data(isCategorical), 'UniformOutput', false);

isCategorical = cellfun(@(categorical, data) repmat(categorical, [1 size(data,2)]), num2cell(isCategorical), other_data, 'UniformOutput', false);

% If Incorrect trials were removed in the original fit, do so again
if ~gamParams.includeIncorrect
    other_data = cellfun(@(x) x(~incorrect, :), other_data, 'UniformOutput', false);
end

%% Figure out the matrix of other inputs
other_inputs = [other_data{:}];
other_inputs = other_inputs(sample_ind, :);

%% Compute covariance matrix used for Mahalanobis distances:

% Find weights
other_isCategorical = [isCategorical{:} true(1, size(hist ,2))];
[summed_weights] = apc_weights(other_inputs, other_isCategorical);

%% Compute the difference between the two rules

orientationCov = GLMCov;
orientationCov(rule_ind).data(:) = find(ismember(orientationCov(rule_ind).levels, 'Orientation'));

[orientation_design] = gamModelMatrix(gamParams.regressionModel_str, orientationCov, spikes(:,1));
if ~gamParams.includeIncorrect
    orientation_design = orientation_design(~incorrect, :);
end
orientation_design = orientation_design(sample_ind, :);

orientation_est = nan(numData, numNeurons, numSim);
for neuron_ind = 1:numNeurons,
    orientation_est(:, neuron_ind, :) = exp(orientation_design*squeeze(par_est(:, neuron_ind, :)))*1000;
end

colorCov = GLMCov;
colorCov(rule_ind).data(:) = find(ismember(colorCov(rule_ind).levels, 'Color'));
[color_design] = gamModelMatrix(gamParams.regressionModel_str, colorCov, spikes(:,1));
if ~gamParams.includeIncorrect
    color_design = color_design(~incorrect, :);
end
color_design = color_design(sample_ind, :);

color_est = nan(numData, numNeurons, numSim);
for neuron_ind = 1:numNeurons,
    color_est(:, neuron_ind, :) = exp(color_design*squeeze(par_est(:, neuron_ind, :)))*1000;
end

rule_diff_est = color_est - orientation_est;

num = sum(bsxfun(@times, summed_weights, rule_diff_est));
abs_num = sum(bsxfun(@times, summed_weights, abs(rule_diff_est)));
rms_num = sum(bsxfun(@times, summed_weights, rule_diff_est.^2));

den = sum(summed_weights);

apc = squeeze(num./den);
abs_apc = squeeze(abs_num./den);
rms_apc = squeeze(sqrt(rms_num)./den);

for neuron_ind = 1:numNeurons,
    avpred(neuron_ind).apc = apc(neuron_ind, :);
    avpred(neuron_ind).abs_apc = abs_apc(neuron_ind, :);
    avpred(neuron_ind).rms_apc = rms_apc(neuron_ind, :);
end

[avpred.numSamples] = deal(numSamples);
[avpred.numSim] = deal(numSim);
[avpred.session_name] = deal(session_name);
[avpred.model_name] = deal(model_name);
[avpred.wire_number] = deal(neurons.wire_number);
[avpred.unit_number] = deal(neurons.unit_number);
[avpred.pfc] = deal(neurons.pfc);
[avpred.monkey] = deal(neurons.monkey);
baseline = num2cell(mean(exp(par_est(1, :, :))*1000, 3));
[avpred.baseline_firing] = deal(baseline{:});

save_file_name = sprintf('%s/%s_APC.mat', save_folder, session_name);
saveMillerlab('edeno', save_file_name, 'avpred');

end