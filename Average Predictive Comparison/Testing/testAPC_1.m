clear variables; close all; clc; profile off;
%% Make sure we know the model and GLM covariates
numFolds = 1;
isOverwrite = true;
ridgeLambda = 1E-3;
smoothLambda = 0;

% Simulate Session
numTrials = 1000;
[SpikeCov, trialTime, isCorrect, isAttempted, trialID] = simSession(numTrials);

% Load Common Parameters
mainDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', mainDir), 'covInfo');

trueRate = nan(size(trialTime));

cov_id = @(cov_name, level_name) find(ismember(covInfo(cov_name).levels, level_name));
level_ind = @(cov_name, level_name) ismember(SpikeCov(cov_name).data, cov_id(cov_name, level_name));

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
factorOfInterest = 'Rule';

apcJob = computeAPC(model, timePeriod, factorOfInterest, 'isLocal', true, 'sessionNames', {'test'}, 'isWeighted', false);
%%
figure;
subplot(1,3,1);
plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.apc), [0.025 .5 .975],  2), 'b');
hline(orientRate - colorRate, 'r:' , 'True Difference');
box off;
title('APC');

subplot(1,3,2);
plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.abs_apc), [0.025 .5 .975],  2), 'b');
hline(abs(orientRate - colorRate), 'r:' , 'True Difference');
box off;
title('Abs APC');

subplot(1,3,3);
plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.norm_apc), [0.025 .5 .975],  2), 'b');
hline((orientRate - colorRate) / (orientRate + colorRate), 'r:', 'True Difference');
box off;
title('Norm APC');

suptitle(sprintf('%s: %s', factorOfInterest, apcJob{1}.comparisonNames{1}));
