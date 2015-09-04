clear all; close all; clc;

% GAMpred parameters
ridgeLambda = 0;
numFolds = 5;
isOverwrite = true;

% Simulate Session
numTrials = 2000;
[GLMCov, trial_time] = simSession(numTrials);

%% Binary Categorical Covariate - Rule
Rate = nan(size(trial_time));

cov_ind = @(cov_name) ismember({GLMCov.name}, cov_name);
cov_id = @(cov_name, level_name) find(ismember(GLMCov(cov_ind(cov_name)).levels, level_name));
level_ind = @(cov_name, level_name) ismember(GLMCov(cov_ind(cov_name)).data, cov_id(cov_name, level_name));

colorRate = 1;
orientRate = 5;
ruleRatio = orientRate / colorRate;

Rate(level_ind('Rule', 'Color')) = colorRate;
Rate(level_ind('Rule', 'Orientation')) = orientRate;

% Correct Model
model = 'Rule';
[neurons, gam, designMatrix, spikes, model_dir] = testComputeGAMfit_wrapper(model, Rate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, ...
    'isPrediction', true);

% Misspecified Model
model = 'Response Direction';
[neurons_misspecified, gam_misspecified, designMatrix_misspecified, spikes_misspecified, model_dir] = testComputeGAMfit_wrapper(model, Rate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, ...
    'isPrediction', true, 'spikes', spikes);


%% Plot
figure;

% AUC
subplot(1,2,1);
meanPredError = [squeeze(mean([neurons.pred_error(:, :, 2)], 1)), squeeze(mean([neurons_misspecified.pred_error(:, :, 2)], 1))];
plot(1:2, meanPredError)
set(gca, 'XTick', 1:2)
set(gca, 'XTickLabel', {'Correct Model', 'Misspecified Model'})
hline(0.5, 'k');
title('AUC')

% MI
subplot(1,2,2);
meanPredError = [squeeze(mean([neurons.pred_error(:, :, 3)], 1)), squeeze(mean([neurons_misspecified.pred_error(:, :, 3)], 1))];
plot(1:2, meanPredError)
set(gca, 'XTick', 1:2)
set(gca, 'XTickLabel', {'Correct Model', 'Misspecified Model'})
hline(0.0, 'k');
title('Mutual Information (bits / spike)')