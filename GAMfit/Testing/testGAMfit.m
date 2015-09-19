clear all; close all; clc;

% GAMpred parameters
ridgeLambda = 0;
numFolds = 1;
isOverwrite = true;
ridgeLambda = 0;
smoothLambda = 0;

% Simulate Session
numTrials = 2000;
[GLMCov, trial_time, isCorrect, isAttempted, trial_id] = simSession(numTrials);

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
[neurons, stats, gam, designMatrix, spikes, model_dir, gamParams] = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

% Misspecified Model
model = 'Response Direction';
[neurons_misspecified, stats_misspecified, gam_misspecified, designMatrix_misspecified, spikes_misspecified, model_dir, gamParams_misspecified] = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false, 'spikes', spikes);

%% KS-Test: Time Rescaling
figure;
uniformCDFvalues = stats.timeRescale.uniformCDFvalues;
numSpikes = stats.timeRescale.numSpikes;
CI = 1.36 / sqrt(numSpikes);

plot(uniformCDFvalues, stats.timeRescale.sortedKS); hold all;
plot(uniformCDFvalues, stats_misspecified.timeRescale.sortedKS);
plot(uniformCDFvalues, (uniformCDFvalues + CI), 'k--');
plot(uniformCDFvalues, (uniformCDFvalues - CI), 'k--');
axis([0 1 0 1]);
line;
legend('True Model', 'Mispecified Model');
title('KS Plot');
xlabel('Empirical CDF');
ylabel('Model CDF');
box off;

figure;
plot(uniformCDFvalues, stats.timeRescale.sortedKS - uniformCDFvalues); hold all;
plot(uniformCDFvalues, stats_misspecified.timeRescale.sortedKS - uniformCDFvalues);
ylabel('Model CDF - Empirical CDF');
legend('True Model', 'Mispecified Model');
hline([-CI CI], 'k--');
hline(0, 'k-')

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

%%
% Time model
numFolds = 5;

adjustedTrueRate = trueRate;
adjustedTrueRate((~gamParams.includeIncorrect .* ~isCorrect) | (~gamParams.includeFixationBreaks .* ~isAttempted)) = [];

model = 's(Rule, Trial Time)';
[neurons, stats, gam, designMatrix, spikes, model_dir, gamParams] = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

est = exp(designMatrix * (neurons.par_est' * gam.constraints)') * 1000;

figure;
plot(est(ismember(trial_id, [1:40])))
hold all;
plot(adjustedTrueRate(ismember(trial_id, [1:40])));

figure;
uniformCDFvalues = stats.timeRescale.uniformCDFvalues;
numSpikes = stats.timeRescale.numSpikes;
CI = 1.36 / sqrt(numSpikes);

plot(uniformCDFvalues, stats.timeRescale.sortedKS); hold all;
plot(uniformCDFvalues, (uniformCDFvalues + CI), 'k--');
plot(uniformCDFvalues, (uniformCDFvalues - CI), 'k--');
axis([0 1 0 1]);
line;
title('KS Plot');
xlabel('Empirical CDF');
ylabel('Model CDF');
box off;
