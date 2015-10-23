clear variables; close all; clc; profile off;

% GAMpred parameters
isOverwrite = true;
numFolds = 5;
ridgeLambda = 1;
smoothLambda = 10.^(-3:3);

% Simulate Session
numTrials = 1000;
[SpikeCov, trialTime, isCorrect, isAttempted, trialID, percentTrials] = simSession(numTrials);
percentTrials = accumarray(trialTime, percentTrials,  [], @mean);

% Load Common Parameters
mainDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', mainDir), 'covInfo');
%%
trueRate = nan(size(trialTime));

cov_id = @(cov_name, level_name) find(ismember(covInfo(cov_name).levels, level_name));
level_ind = @(cov_name, level_name) ismember(SpikeCov(cov_name).data, cov_id(cov_name, level_name));

colorLeftRate = 1;
orientLeftRate = 5;

colorRightRate = 3;
orientRightRate = 1;

trueRate(level_ind('Rule', 'Color') & level_ind('Response Direction', 'Right')) = colorRightRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Response Direction', 'Left')) = colorLeftRate;

trueRate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Right') & trialTime <= 100) = orientRightRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Right') & trialTime > 100) = orientRightRate * 2;

trueRate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Left') & trialTime <= 100) = orientLeftRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Left') & trialTime > 100) = orientLeftRate * 2;
%%
model = 's(Rule * Response Direction, Trial Time)';
[neurons, stats, gam, designMatrix, spikes, gamParams] = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);
%%
timePeriod = 'Testing';
factorOfInterest = 'Response Direction';

apcJob = computeRuleByAPC(model, timePeriod, factorOfInterest, 'isLocal', true, 'sessionNames', {'test'}, 'isWeighted', false);
%%
% Right Response
trueDiffRight = (orientRightRate - colorRightRate) .* ones(size(apcJob{1}.trialTime));
trueDiffRight(apcJob{1}.trialTime > 100) = ((orientRightRate * 2) - colorRightRate);

trueSumRight = (orientRightRate + colorRightRate) .* ones(size(apcJob{1}.trialTime));
trueSumRight(apcJob{1}.trialTime > 100) = ((orientRightRate * 2) + colorRightRate);

figure;
subplot(2,3,1);
plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.apc(1, :, :)), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trialTime, trueDiffRight, 'r.');
plot(apcJob{1}.trialTime, percentTrials, 'g--');
box off;
title(sprintf('APC %s: %s', factorOfInterest, apcJob{1}.byLevels{1}));

subplot(2,3,2);
plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.abs_apc(1, :, :)), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trialTime, abs(trueDiffRight), 'r.');
box off;
title(sprintf('Abs APC %s: %s', factorOfInterest, apcJob{1}.byLevels{1}));

subplot(2,3,3);
plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.norm_apc(1, :, :)), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trialTime, trueDiffRight ./ trueSumRight, 'r.');
box off;
title(sprintf('Norm APC %s: %s', factorOfInterest, apcJob{1}.byLevels{1}));

% Left Response
trueDiffLeft = (orientLeftRate - colorLeftRate) .* ones(size(apcJob{1}.trialTime));
trueDiffLeft(apcJob{1}.trialTime > 100) = ((orientLeftRate * 2) - colorLeftRate);

trueSumLeft = (orientLeftRate + colorLeftRate) .* ones(size(apcJob{1}.trialTime));
trueSumLeft(apcJob{1}.trialTime > 100) = ((orientLeftRate * 2) + colorLeftRate);

subplot(2,3,4);
plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.apc(2, :, :)), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trialTime, trueDiffLeft, 'r.' );
plot(apcJob{1}.trialTime, trueDiffLeft, 'r.' );
box off;
title(sprintf('APC %s: %s', factorOfInterest, apcJob{1}.byLevels{2}));

subplot(2,3,5);
plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.abs_apc(2, :, :)), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trialTime, abs(trueDiffLeft), 'r.' );
box off;
title(sprintf('Abs APC %s: %s', factorOfInterest, apcJob{1}.byLevels{2}));

subplot(2,3,6);
plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.norm_apc(2, :, :)), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trialTime, trueDiffLeft ./ trueSumLeft, 'r.' );
box off;
title(sprintf('Norm APC %s: %s', factorOfInterest, apcJob{1}.byLevels{2}));

