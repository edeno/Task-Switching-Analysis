function [avpred] = avrPredComp_Rule2(session_name, timePeriod, model_name, numSim, numSamples, save_folder, main_dir)

load([main_dir, '/paramSet.mat'], 'cov_info', 'data_info');
GLMCov_name = sprintf('%s/%s/GLMCov/%s_GLMCov.mat', data_info.processed_dir, timePeriod, session_name);
load(GLMCov_name, 'GLMCov', 'incorrect', 'spikes')
GAMfit_name = sprintf('%s/%s/Models/%s/%s_GAMfit.mat', data_info.processed_dir, timePeriod, model_name, session_name);
load(GAMfit_name, 'gam', 'gamParams', 'neurons', 'designMatrix', 'numNeurons');

rule_ind = ismember({GLMCov.name}, 'Rule');
switch_ind = ismember({GLMCov.name}, 'Switch History');
prev_error_ind = ismember({GLMCov.name}, 'Previous Error History');
cong_hist_ind = ismember({GLMCov.name}, 'Congruency History');
response_dir_ind = ismember({GLMCov.name}, 'Response Direction');
prep_time_ind = ismember({GLMCov.name}, 'Normalized Prep Time');

rule = dummyvar(GLMCov(rule_ind).data);
switch_hist = GLMCov(switch_ind).data;
prev_error_hist = dummyvar(GLMCov(prev_error_ind).data);
con_hist = dummyvar(GLMCov(cong_hist_ind).data);
response_dir = dummyvar(GLMCov(response_dir_ind).data);
prep_time = GLMCov(prep_time_ind).data;

% If Incorrect trials were removed in the original fit, do so again
if ~gamParams.includeIncorrect
    rule = rule(~incorrect, :);
    switch_hist = switch_hist(~incorrect, :);
    prev_error_hist = prev_error_hist(~incorrect, :);
    con_hist = con_hist(~incorrect, :);
    response_dir = response_dir(~incorrect, :);
    prep_time = prep_time(~incorrect, :);
end

% Size of Design Matrix
[numData, numPredictors] = size(designMatrix);

other_inputs = [switch_hist prev_error_hist con_hist response_dir prep_time];

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

other_inputs = other_inputs(sample_ind, :);

%% Compute covariance matrix used for Mahalanobis distances:

% Find weights
isCategorical = [false(1, size(switch_hist, 2)) true(1, size(prev_error_hist, 2)) ...
    true(1, size(con_hist, 2)) true(1, size(response_dir, 2))  false(1, size(prep_time, 2))];
[summed_weights] = apc_weights(other_inputs, isCategorical);

orientationCov = GLMCov;
orientationCov(rule_ind).data(:) = find(ismember(orientationCov(rule_ind).levels, 'Orientation'));
[orientation_design] = gamModelMatrix3(gamParams.regressionModel_str, orientationCov, spikes(:,1));
if ~gamParams.includeIncorrect
    orientation_design = orientation_design(~incorrect, :);
end
orientation_design = orientation_design(sample_ind, :);

orientation_est = nan(numData, numNeurons, numSim);
for neuron_ind = 1:numNeurons,
    orientation_est(:, neuron_ind, :) = exp(orientation_design*squeeze(par_est(:, neuron_ind, :)))*1000;
end

colorCov = GLMCov;
colorCov(rule_ind).data(:) = find(ismember(orientationCov(rule_ind).levels, 'Color'));
[color_design] = gamModelMatrix3(gamParams.regressionModel_str, colorCov, spikes(:,1));
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