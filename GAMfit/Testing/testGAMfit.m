clear all; close all; clc;

% GAMpred parameters
ridgeLambda = 0;
numFolds = 1;
isOverwrite = true;

% Simulate Session
numTrials = 2000;
[GLMCov, trial_time, isCorrect, isAttempted] = simSession(numTrials);

%% Binary Categorical Covariate - Rule
trueRate = nan(size(trial_time));

cov_ind = @(cov_name) ismember({GLMCov.name}, cov_name);
cov_id = @(cov_name, level_name) find(ismember(GLMCov(cov_ind(cov_name)).levels, level_name));
level_ind = @(cov_name, level_name) ismember(GLMCov(cov_ind(cov_name)).data, cov_id(cov_name, level_name));

colorRate = 1;
orientRate = 5;
ruleRatio = orientRate / colorRate;

trueRate(level_ind('Rule', 'Color')) = colorRate;
trueRate(level_ind('Rule', 'Orientation')) = orientRate;

% Correct Model
model = 'Rule';
[neurons, gam, designMatrix, spikes, model_dir, gamParams] = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, ...
    'isPrediction', false);

% Misspecified Model
model = 'Response Direction';
[neurons_misspecified, gam_misspecified, designMatrix_misspecified, spikes_misspecified, model_dir, gamParams_misspecified] = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, ...
    'isPrediction', false, 'spikes', spikes);

%% KS-Test: Time Rescaling
figure;
uniformCDFvalues = neurons.stats.timeRescale.uniformCDFvalues;
numSpikes = neurons.stats.timeRescale.numSpikes;
CI = 1.36 / sqrt(numSpikes);

plot(uniformCDFvalues, neurons.stats.timeRescale.sortedKS); hold all;
plot(neurons_misspecified.stats.timeRescale.uniformCDFvalues, neurons_misspecified.stats.timeRescale.sortedKS);
plot(uniformCDFvalues, (uniformCDFvalues + CI), 'k--');
plot(uniformCDFvalues, (uniformCDFvalues - CI), 'k--');
axis([0 1 0 1]);
line;
legend('True Model', 'Mispecified Model');
title('KS Plot');
box off;

%% PSTH Correlation
adjustedTrueRate = trueRate;
adjustedTrueRate((~gamParams.includeIncorrect .* ~isCorrect) | (~gamParams.includeFixationBreaks .* ~isAttempted)) = [];
modelRate = exp(designMatrix * neurons.par_est) * 1000;
misspecifiedModelRate = exp(designMatrix_misspecified * neurons_misspecified.par_est) * 1000;

figure;
subplot(2,1,1);
plot(adjustedTrueRate); hold all;
plot(modelRate, '--');
title(sprintf('Corr: %d', corr(modelRate, adjustedTrueRate)));

subplot(2,1,2);
plot(adjustedTrueRate); hold all;
plot(misspecifiedModelRate, '--');
title(sprintf('Corr: %d', corr(misspecifiedModelRate, adjustedTrueRate)));
legend('True Rate', 'Model Rate');
