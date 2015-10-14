clear variables; close all; clc; profile off;

% GAMpred parameters
isOverwrite = true;
numFolds = 5;
ridgeLambda = 0;
smoothLambda = 10.^(-3:3);

% Simulate Session
numTrials = 1000;
[GLMCov, trial_time, isCorrect, isAttempted, trial_id] = simSession(numTrials);
%%
trueRate = nan(size(trial_time));

cov_ind = @(cov_name) ismember({GLMCov.name}, cov_name);
cov_id = @(cov_name, level_name) find(ismember(GLMCov(cov_ind(cov_name)).levels, level_name));
level_ind = @(cov_name, level_name) ismember(GLMCov(cov_ind(cov_name)).data, cov_id(cov_name, level_name));

colorRate = 1;
orientRate = 5;
leftResponseMultiplier = 1.5;
ruleRatio = orientRate / colorRate;

trueRate(level_ind('Rule', 'Color')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & trial_time <= 100) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & trial_time > 100) = orientRate * 2;
trueRate(level_ind('Response Direction', 'Left')) = trueRate(level_ind('Response Direction', 'Left')) * leftResponseMultiplier ;

%%
model = 's(Rule, Trial Time) + s(Response Direction, Trial Time)';
[neurons, stats, gam, designMatrix, spikes, gamParams] = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

%%
timePeriod = 'Testing';
type = 'Rule';

apcJob = computeAPC(model, timePeriod, type, 'isLocal', true, 'session_names', {'test'}, 'isWeighted', false);
%%
trueDiff = (orientRate - colorRate) .* ones(size(apcJob{1}.trial_time));
trueDiff(apcJob{1}.trial_time > 100) = ((orientRate * 2) - colorRate);

trueSum = (orientRate + colorRate) .* ones(size(apcJob{1}.trial_time));
trueSum(apcJob{1}.trial_time > 100) = ((orientRate * 2) + colorRate);

figure;
subplot(1,3,1);
plot(apcJob{1}.trial_time, quantile(squeeze(apcJob{1}.apc), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trial_time, trueDiff, 'r.' );
box off;
title('APC');
vline(260);

subplot(1,3,2);
plot(apcJob{1}.trial_time, quantile(squeeze(apcJob{1}.abs_apc), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trial_time, abs(trueDiff), 'r.' );
box off;
title('Abs APC');
vline(260);

subplot(1,3,3);
plot(apcJob{1}.trial_time, quantile(squeeze(apcJob{1}.norm_apc), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trial_time, trueDiff ./ trueSum, 'r.' );
box off;
title('Norm APC');
vline(260);

suptitle(sprintf('%s: %s', type, apcJob{1}.levels{1}));

%%
timePeriod = 'Testing';
type = 'Response Direction';
apcJob(2) = computeAPC(model, timePeriod, type, 'isLocal', true, 'session_names', {'test'}, 'isWeighted', false);
%%
figure;
subplot(1,3,1);
plot(apcJob{2}.trial_time, quantile(squeeze(apcJob{2}.apc), [0.025 .5 .975],  2), 'b');
hold on;

box off;
title('APC');
vline(260);

subplot(1,3,2);
plot(apcJob{2}.trial_time, quantile(squeeze(apcJob{2}.abs_apc), [0.025 .5 .975],  2), 'b');
hold on;

box off;
title('Abs APC');
vline(260);

subplot(1,3,3);
plot(apcJob{2}.trial_time, quantile(squeeze(apcJob{2}.norm_apc), [0.025 .5 .975],  2), 'b');
hold on;

box off;
title('Norm APC');
vline(260);

suptitle(sprintf('%s: %s', type, apcJob{2}.levels{1}));