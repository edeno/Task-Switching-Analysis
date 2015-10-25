clear variables; close all; clc; profile off;

% GAMpred parameters
isOverwrite = true;
numFolds = 5;
ridgeLambda = 1;
smoothLambda = 10.^(-3:3);

% Simulate Session
numTrials = 2000;
[spikeCov, trialTime, isCorrect, isAttempted, trialID] = simSession(numTrials);

% Load Common Parameters
mainDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', mainDir), 'covInfo');
%%
trueRate = nan(size(trialTime));

cov_id = @(cov_name, level_name) find(ismember(covInfo(cov_name).levels, level_name));
level_ind = @(cov_name, level_name) ismember(spikeCov(cov_name), cov_id(cov_name, level_name));

colorRate = 1;
orientRate = 5;
leftResponseMultiplier = 1.5;
ruleRatio = orientRate / colorRate;

trueRate(level_ind('Rule', 'Color')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & trialTime <= 100) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & trialTime > 100) = orientRate * 2;
trueRate(level_ind('Response Direction', 'Left')) = trueRate(level_ind('Response Direction', 'Left')) * leftResponseMultiplier ;
%%
model = 's(Rule, Trial Time) + s(Response Direction, Trial Time)';
[neurons, stats, gam, designMatrix, spikes, gamParams] = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

adjustedTrueRate = trueRate;
adjustedTrueRate((~gamParams.includeIncorrect .* ~isCorrect) | (~gamParams.includeFixationBreaks .* ~isAttempted)) = [];

est = exp(designMatrix * (neurons.parEst' * gam.constraints)') * 1000;
%%
fittedLevel_ind = @(level_name) logical(designMatrix(:, strcmp(gam.levelNames, level_name)));
figure;

subplot(3,2,1:2)
plot(adjustedTrueRate(ismember(gam.trialID, [1:70])), 'r');
hold all;
plot(est(ismember(gam.trialID, [1:70])), 'b')
ylabel('Firing Rate (Hz)')
legend('True Rate', 'Model Fit');
box off;

subplot(3,2,3);
plot(gam.trialTime(~fittedLevel_ind('Orientation')), adjustedTrueRate(~fittedLevel_ind('Orientation')), 'r.')
hold all;
plot(gam.trialTime(~fittedLevel_ind('Orientation')), est(~fittedLevel_ind('Orientation')), 'b.');
ylim([0 max(adjustedTrueRate) + 5]);
title('Color Trials');
box off;
ylabel('Firing Rate (Hz)')
xlabel('Time (ms)')

subplot(3,2,4);
plot(gam.trialTime(fittedLevel_ind('Orientation')), adjustedTrueRate(fittedLevel_ind('Orientation')), 'r.')
hold all;
plot(gam.trialTime(fittedLevel_ind('Orientation')), est(fittedLevel_ind('Orientation')), 'b.')
title('Orientation Trials');
ylim([0 max(adjustedTrueRate) + 5]);
ylabel('Firing Rate (Hz)')
xlabel('Time (ms)')
box off;

subplot(3,2,5);
plot(gam.trialTime(~fittedLevel_ind('Left')), adjustedTrueRate(~fittedLevel_ind('Left')), 'r.')
hold all;
plot(gam.trialTime(~fittedLevel_ind('Left')), est(~fittedLevel_ind('Left')), 'b.')
title('Left Response Trials');
ylim([0 max(adjustedTrueRate) + 5]);
ylabel('Firing Rate (Hz)')
xlabel('Time (ms)')
box off;

subplot(3,2,6);
plot(gam.trialTime(fittedLevel_ind('Left')), adjustedTrueRate(fittedLevel_ind('Left')), 'r.')
hold all;
plot(gam.trialTime(fittedLevel_ind('Left')), est(fittedLevel_ind('Left')), 'b.')
title('Left Response Trials');
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

figure;
plot(uniformCDFvalues, stats.timeRescale.sortedKS - uniformCDFvalues); hold all;
ylabel('Model CDF - Empirical CDF');
hline([-CI CI], 'k--');
hline(0, 'k-');
box off;

figure;
subplot(1,2,1);
plot(stats.timeRescale.uniformRescaledISIs(1:end-1), stats.timeRescale.uniformRescaledISIs(2:end), '.');
xlabel('k - 1'); ylabel('k');
box off;
title('Consecutive Intervals of Uniform ISIs');

subplot(1,2,2);
CI = 1.96 / sqrt(numSpikes);
[coef, lags] = xcorr(stats.timeRescale.normalRescaledISIs, 'coeff');
hline([-CI CI], 'k--');
hline(0, 'k-');
plot(lags, coef, '.');
box off;
ylabel('Correlation Coefficient');
xlabel('Lags');
title('Autocorrelation of Uniform ISIs');