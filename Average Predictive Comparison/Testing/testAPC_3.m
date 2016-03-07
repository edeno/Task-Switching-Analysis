clear variables; close all; clc; profile off;
% GAMpred parameters
isOverwrite = true;
numFolds = 5;
ridgeLambda = 0;
smoothLambda = 10.^(-3:3);

% Simulate Session
numTrials = 1000;
[spikeCov, trialTime, isCorrect, isAttempted, trialID] = simSession(numTrials);

% Load Common Parameters
mainDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', mainDir), 'covInfo');
%%
trueRate = nan(size(trialTime));

cov_id = @(cov_name, level_name) find(ismember(covInfo(cov_name).levels, level_name));
level_ind = @(cov_name, level_name) ismember(spikeCov(cov_name), cov_id(cov_name, level_name));

colorRate = 3;
orientRate = 7;
leftResponseRateDiff = 2;
ruleRatio = orientRate / colorRate;

trueRate(level_ind('Rule', 'Color')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & trialTime <= 100) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & trialTime > 100) = orientRate * 2;
trueRate(level_ind('Response Direction', 'Left')) = trueRate(level_ind('Response Direction', 'Left')) - leftResponseRateDiff ;

%%
model = 's(Rule, Trial Time) + s(Response Direction, Trial Time)';
testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

%%
timePeriod = 'Testing';
type = 'Rule';

apcJob = computeAPC(model, timePeriod, type, 'isLocal', true, 'sessionNames', {'test'}, 'isWeighted', false, 'overwrite', true);
%%
trueDiff = (orientRate - colorRate) .* ones(size(apcJob{1}.trialTime));
trueDiff(apcJob{1}.trialTime > 100) = ((orientRate * 2) - colorRate);

trueSum = (orientRate + colorRate) .* ones(size(apcJob{1}.trialTime));
trueSum(apcJob{1}.trialTime > 100) = ((orientRate * 2) + colorRate);

figure;
subplot(1,3,1);
plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.apc), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trialTime, trueDiff, 'r.' );
box off;
title('APC');
vline(260);

subplot(1,3,2);
plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.abs_apc), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trialTime, abs(trueDiff), 'r.' );
box off;
title('Abs APC');
vline(260);

subplot(1,3,3);
plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.norm_apc), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{1}.trialTime, trueDiff ./ trueSum, 'r.' );
box off;
title('Norm APC');
vline(260);

suptitle(sprintf('%s: %s', type, apcJob{1}.comparisonNames{1}));

%%
timePeriod = 'Testing';
type = 'Response Direction';
apcJob(2) = computeAPC(model, timePeriod, type, 'isLocal', true, 'sessionNames', {'test'}, 'isWeighted', false, 'overwrite', true);
%%
figure;
subplot(1,3,1);
plot(apcJob{2}.trialTime, quantile(squeeze(apcJob{2}.apc), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{2}.trialTime, -1 * leftResponseRateDiff * ones(size(apcJob{2}.trialTime)), 'r')

box off;
title('APC');
vline(260);

subplot(1,3,2);
plot(apcJob{2}.trialTime, quantile(squeeze(apcJob{2}.abs_apc), [0.025 .5 .975],  2), 'b');
hold on;
plot(apcJob{2}.trialTime, leftResponseRateDiff * ones(size(apcJob{2}.trialTime)), 'r')

box off;
title('Abs APC');
vline(260);

subplot(1,3,3);
plot(apcJob{2}.trialTime, quantile(squeeze(apcJob{2}.norm_apc), [0.025 .5 .975],  2), 'b');
hold on;

box off;
title('Norm APC');
vline(260);

suptitle(sprintf('%s: %s', type, apcJob{2}.comparisonNames{1}));