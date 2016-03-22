clear variables; close all; clc; profile off;

% Simulate Session
numTrials = 2000;
[spikeCov, trial_time, isCorrect, isAttempted, trial_id] = simSession(numTrials);

% Load Common Parameters
mainDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', mainDir), 'covInfo');
% Binary Categorical Covariate - Rule
trueRate = nan(size(trial_time));

cov_id = @(cov_name, level_name) find(ismember(covInfo(cov_name).levels, level_name));
level_ind = @(cov_name, level_name) ismember(spikeCov(cov_name), cov_id(cov_name, level_name));

colorRate = 1;
orientRate = 1.05;
trueRate(level_ind('Rule', 'Color')) = colorRate;
trueRate(level_ind('Rule', 'Orientation')) = orientRate;

[~, p_small, obs_small, randDiff_small] = testFiringRatePermutationAnalysis_wrapper('Rule', trueRate);

colorRate = 5;
orientRate = 1;
trueRate(level_ind('Rule', 'Color')) = colorRate;
trueRate(level_ind('Rule', 'Orientation')) = orientRate;

[~, p_large, obs_large, randDiff_large] = testFiringRatePermutationAnalysis_wrapper('Rule', trueRate);

colorRate = 5;
orientRate = 1;
trueRate(level_ind('Rule', 'Color')) = colorRate;
trueRate(level_ind('Rule', 'Orientation')) = orientRate;

[ ~, p_wrong, obs_wrong, randDiff_wrong] = testFiringRatePermutationAnalysis_wrapper('Rule Repetition', trueRate);
%%
figure;
subplot(3,2,1);
hist(randDiff_small, 50);
vline(obs_small);
title(sprintf('p-value: %.3f', p_small));
subplot(3,2,2);
hist(randDiff_large, 50);
vline(obs_large);
title(sprintf('p-value: %.3f', p_large));
subplot(3,2,3);
hist(randDiff_wrong(1,:), 50);
vline(obs_wrong(1));
title(sprintf('p-value: %.3f', p_wrong(1)));
subplot(3,2,3);
hist(randDiff_wrong(2,:), 50);
vline(obs_wrong(2));
title(sprintf('p-value: %.3f', p_wrong(2)));
subplot(3,2,5);
hist(randDiff_wrong(3,:), 50);
vline(obs_wrong(3));
title(sprintf('p-value: %.3f', p_wrong(3)));
subplot(3,2,6);
hist(squeeze(randDiff_wrong(3,:)), 50);
vline(obs_wrong(3));
title(sprintf('p-value: %.3f', p_wrong(3)));