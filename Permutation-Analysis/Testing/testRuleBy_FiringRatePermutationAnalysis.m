clear variables; close all; clc; profile off;

% Simulate Session
numTrials = 2000;
[spikeCov, trial_time, isCorrect, isAttempted, trial_id] = simSession(numTrials);

% Load Common Parameters
mainDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', mainDir), 'covInfo');
trueRate = nan(size(trial_time));

cov_id = @(cov_name, level_name) find(ismember(covInfo(cov_name).levels, level_name));
level_ind = @(cov_name, level_name) ismember(spikeCov(cov_name), cov_id(cov_name, level_name));

%% No Increase in firing rate difference on Rep1 (expected p(1) is large)
colorRate = 1;
orientRate = 5;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition1')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition2')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition3')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition4')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition5+')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition1')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition2')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition3')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition4')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition5+')) = orientRate;

[~, p_noEffect, obs_noEffect, randDiff_noEffect] = testRuleBy_FiringRatePermutationAnalysis_wrapper('Rule Repetition', trueRate);
%% Orientation Increase on Rep1 (expected p(1) is small)
colorRate = 1;
orientRate = 5;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition1')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition2')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition3')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition4')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition5+')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition1')) = orientRate * 2;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition2')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition3')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition4')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition5+')) = orientRate;

[~, p_orientIncrease, obs_orientIncrease, randDiff_orientIncrease] = testRuleBy_FiringRatePermutationAnalysis_wrapper('Rule Repetition', trueRate);
%% Color Increase on Rep1 (expected p(1) is small)
colorRate = 5;
orientRate = 1;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition1')) = colorRate * 2;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition2')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition3')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition4')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition5+')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition1')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition2')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition3')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition4')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition5+')) = orientRate;

[~, p_colorIncrease, obs_colorIncrease, randDiff_colorIncrease] = testRuleBy_FiringRatePermutationAnalysis_wrapper('Rule Repetition', trueRate);
%% Decrease in Firing Rate Difference (expected p(1) is large)
colorRate = 5;
orientRate = 1;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition1')) = colorRate * 0.5;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition2')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition3')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition4')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition5+')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition1')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition2')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition3')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition4')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition5+')) = orientRate;

[~, p_colorDecrease, obs_colorDecrease, randDiff_colorDecrease] = testRuleBy_FiringRatePermutationAnalysis_wrapper('Rule Repetition', trueRate);
%% Higher firing rate difference but different rule preference on first trial (expected p(1) is small)
colorRate = 5;
orientRate = 1;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition1')) = orientRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition2')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition3')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition4')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition5+')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition1')) = colorRate * 2;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition2')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition3')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition4')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition5+')) = orientRate;

[~, p_switched, obs_switched, randDiff_switched] = testRuleBy_FiringRatePermutationAnalysis_wrapper('Rule Repetition', trueRate);
%%
figure;
subplot(3,2,1);
hist(randDiff_noEffect(1, :), 50);
vline(obs_noEffect(1));
title(sprintf('No Effect, p-value: %.3f', p_noEffect));
subplot(3,2,2);
hist(randDiff_orientIncrease(1, :), 50);
vline(obs_orientIncrease(1));
title(sprintf('Orient Increase on Rep 1, p-value: %.3f', p_orientIncrease));
subplot(3,2,3);
hist(randDiff_colorIncrease(1,:), 50);
vline(obs_colorIncrease(1));
title(sprintf('Color Increase on Rep 1, p-value: %.3f', p_colorIncrease(1)));
subplot(3,2,4);
hist(randDiff_colorDecrease(1,:), 50);
vline(obs_colorDecrease(1));
title(sprintf('Color Decrease on Rep 1, p-value: %.3f', p_colorDecrease(1)));
subplot(3,2,5);
hist(randDiff_switched(1,:), 50);
vline(obs_switched(1));
title(sprintf('Switch Rule Preference on Rep 1, p-value: %.3f', p_switched(1)));