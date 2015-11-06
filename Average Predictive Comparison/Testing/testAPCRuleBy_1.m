clear variables; close all; clc; profile off;
%% Make sure we know the model and GLM covariates
numFolds = 1;
isOverwrite = true;
ridgeLambda = 1;
smoothLambda = 0;

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
factorOfInterest = 'Response Direction';

profile -memory on;
apcJob = computeRuleByAPC(model, timePeriod, factorOfInterest, 'isLocal', true, 'sessionNames', {'test'}, 'isWeighted', false);
profile viewer;
%%
figure;
numLevels = length(apcJob{1}.byLevels);
plot_ind = @ (x, level_ind) sub2ind([3, numLevels], x, level_ind);

for level_ind = 1:numLevels, 
    subplot(numLevels, 3, plot_ind(1, level_ind));
    plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.apc(level_ind, :, :)), [0.025 .5 .975],  2), 'b');
    hline(orientRate - colorRate, 'r:' , 'True Difference');
    box off;
    title(sprintf('APC %s: %s', factorOfInterest, apcJob{1}.byLevels{level_ind}));
    
    subplot(numLevels, 3, plot_ind(2, level_ind));
    plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.abs_apc(level_ind, :, :)), [0.025 .5 .975],  2), 'b');
    hline(abs(orientRate - colorRate), 'r:' , 'True Difference');
    box off;
   title(sprintf('Abs APC %s: %s', factorOfInterest, apcJob{1}.byLevels{level_ind}));
    
   subplot(numLevels, 3, plot_ind(3, level_ind));
    plot(apcJob{1}.trialTime, quantile(squeeze(apcJob{1}.norm_apc(level_ind, :, :)), [0.025 .5 .975],  2), 'b');
    hline((orientRate - colorRate) / (orientRate + colorRate), 'r:', 'True Difference');
    box off;
    title(sprintf('Norm %s: %s', factorOfInterest, apcJob{1}.byLevels{level_ind}));
end

    