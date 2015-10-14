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

colorLeftRate = 1;
colorRightRate = 3;
orientLeftRate = 5;
orientRightRate = 7;

trueRate(level_ind('Rule', 'Color') & level_ind('Response Direction', 'Right')) = colorRightRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Response Direction', 'Left')) = colorLeftRate;

trueRate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Right') & trial_time <= 100) = orientRightRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Right') & trial_time > 100) = orientRightRate * 2;

trueRate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Left') & trial_time <= 100) = orientLeftRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Left') & trial_time > 100) = orientLeftRate * 2;


%%
model = 's(Rule * Response Direction, Trial Time)';
[neurons, stats, gam, designMatrix, spikes, gamParams] = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

%%
timePeriod = 'Testing';
type = 'Response Direction';

apcJob = computeRuleByAPC(model, timePeriod, type, 'isLocal', true, 'session_names', {'test'}, 'isWeighted', false);

%%
% Right Response

trueDiffRight = (orientRightRate - colorRightRate) .* ones(size(apcJob{1}.trial_time));
trueRightRight(apcJob{1}.trial_time > 100) = ((orientRightRate * 2) - colorRightRate);

trueSumRight = (orientRightRate + colorRightRate) .* ones(size(apcJob{1}.trial_time));
trueSumRight(apcJob{1}.trial_time > 100) = ((orientRightRate * 2) + colorRightRate);

figure;
subplot(1,3,1);
plot(apcJob{1}.trial_time, quantile(squeeze(apcJob{1}.apc(1, :, :)), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trial_time, trueDiffRight, 'r.' );
box off;
title('APC');

subplot(1,3,2);
plot(apcJob{1}.trial_time, quantile(squeeze(apcJob{1}.abs_apc(1, :, :)), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trial_time, abs(trueDiffRight), 'r.' );
box off;
title('Abs APC');

subplot(1,3,3);
plot(apcJob{1}.trial_time, quantile(squeeze(apcJob{1}.norm_apc(1, :, :)), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trial_time, trueDiffRight ./ trueSumRight, 'r.' );
box off;
title('Norm APC');

suptitle(sprintf('%s: %s', type, apcJob{1}.by_levels{1}));

% Left Response
trueDiffLeft = (orientLeftRate - colorLeftRate) .* ones(size(apcJob{1}.trial_time));
trueDiffLeft(apcJob{1}.trial_time > 100) = ((orientLeftRate * 2) - colorLeftRate);

trueSumLeft = (orientLeftRate + colorLeftRate) .* ones(size(apcJob{1}.trial_time));
trueSumLeft(apcJob{1}.trial_time > 100) = ((orientLeftRate * 2) + colorLeftRate);

figure;
subplot(1,3,1);
plot(apcJob{1}.trial_time, quantile(squeeze(apcJob{1}.apc(2, :, :)), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trial_time, trueDiffLeft, 'r.' );
box off;
title('APC');

subplot(1,3,2);
plot(apcJob{1}.trial_time, quantile(squeeze(apcJob{1}.abs_apc(2, :, :)), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trial_time, abs(trueDiffLeft), 'r.' );
box off;
title('Abs APC');

subplot(1,3,3);
plot(apcJob{1}.trial_time, quantile(squeeze(apcJob{1}.norm_apc(2, :, :)), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trial_time, trueDiffLeft ./ trueSumLeft, 'r.' );
box off;
title('Norm APC');

suptitle(sprintf('%s: %s', type, apcJob{1}.by_levels{2}));


