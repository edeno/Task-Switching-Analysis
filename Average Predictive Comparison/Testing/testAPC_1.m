clear variables; close all; clc; profile off;
%% Make sure we know the model and GLM covariates
numFolds = 1;
isOverwrite = true;
ridgeLambda = 1E-3;
smoothLambda = 0;

% Simulate Session
numTrials = 2000;
[GLMCov, trial_time, isCorrect, isAttempted, trial_id] = simSession(numTrials);

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
testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);
%%
timePeriod = 'Testing';
type = 'Rule';

apcJob = computeAPC(model, timePeriod, type, 'isLocal', true, 'session_names', {'test'}, 'isWeighted', false, 'numSamples', 2000);

%%
figure;
subplot(1,3,1);
hist(apcJob{1}.apc, 50)
vline(orientRate - colorRate, 'r:');
vline(mean(apcJob{1}.apc), 'g', 'Estimated Mean Diff.');
vline(quantile(apcJob{1}.apc, [0.025, 0.975]), 'g');
box off;
title('APC');

subplot(1,3,2);
hist(apcJob{1}.abs_apc, 50)
vline(abs(orientRate - colorRate), 'r:');
vline(mean(apcJob{1}.abs_apc), 'g', 'Estimated Mean Diff.');
vline(quantile(apcJob{1}.abs_apc, [0.025, 0.975]), 'g');
box off;
title('Abs APC');

subplot(1,3,3);
hist(apcJob{1}.norm_apc, 50)
box off;
title('Norm APC');

suptitle(sprintf('%s: %s', type, apcJob{1}.levels{1}));
