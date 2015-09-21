clear all; close all; clc;

% GAMpred parameters
isOverwrite = true;
numFolds = 5;
ridgeLambda = 0;
smoothLambda = 10.^(-3:3);

% Simulate Session
numTrials = 2000;
[GLMCov, trial_time, isCorrect, isAttempted, trial_id] = simSession(numTrials);
%%
trueRate = nan(size(trial_time));

cov_ind = @(cov_name) ismember({GLMCov.name}, cov_name);
cov_id = @(cov_name, level_name) find(ismember(GLMCov(cov_ind(cov_name)).levels, level_name));
level_ind = @(cov_name, level_name) ismember(GLMCov(cov_ind(cov_name)).data, cov_id(cov_name, level_name));

colorRate = 1;
orientRate = 5;
ruleRatio = orientRate / colorRate;

trueRate(level_ind('Rule', 'Color')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & trial_time <= 100) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & trial_time > 100) = orientRate * 2;

%%
model = 's(Rule, Trial Time)';
[neurons, stats, gam, designMatrix, spikes, model_dir, gamParams] = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

adjustedTrueRate = trueRate;
adjustedTrueRate((~gamParams.includeIncorrect .* ~isCorrect) | (~gamParams.includeFixationBreaks .* ~isAttempted)) = [];

est = exp(designMatrix * (neurons.par_est' * gam.constraints)') * 1000;

%%

fittedLevel_ind = @(level_name) logical(designMatrix(:, strcmp(gam.level_names, level_name)));
figure;

subplot(2,2,1:2)
plot(adjustedTrueRate(ismember(gam.trial_id, [1:40])), 'r');
hold all;
plot(est(ismember(gam.trial_id, [1:40])), 'b')
ylabel('Firing Rate (Hz)')
legend('True Rate', 'Model Fit');
box off;

subplot(2,2,3);
plot(gam.trial_time(~fittedLevel_ind('Orientation')), adjustedTrueRate(~fittedLevel_ind('Orientation')), 'r.')
hold all;
plot(gam.trial_time(~fittedLevel_ind('Orientation')), est(~fittedLevel_ind('Orientation')), 'b.');
ylim([0 max(adjustedTrueRate) + 5]);
title('Color Trials');
box off;
ylabel('Firing Rate (Hz)')
xlabel('Time (ms)')

subplot(2,2,4);
plot(gam.trial_time(fittedLevel_ind('Orientation')), adjustedTrueRate(fittedLevel_ind('Orientation')), 'r.')
hold all;
plot(gam.trial_time(fittedLevel_ind('Orientation')), est(fittedLevel_ind('Orientation')), 'b.')
title('Orientation Trials');
ylim([0 max(adjustedTrueRate) + 5]);
ylabel('Firing Rate (Hz)')
xlabel('Time (ms)')
box off;

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
