clear variables; close all; clc; profile off;

% GAMpred parameters
ridgeLambda = 10.^(-3:1:3);
numFolds = 5;
isOverwrite = true;

% Simulate Session
numTrials = 2000;
[spikeCov, trialTime, isCorrect, isAttempted, trialID] = simSession(numTrials);

% Load Common Parameters
mainDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', mainDir), 'covInfo');
%% Binary Categorical Covariate - Rule
Rate = nan(size(trialTime));

cov_id = @(cov_name, level_name) find(ismember(covInfo(cov_name).levels, level_name));
level_ind = @(cov_name, level_name) ismember(spikeCov(cov_name), cov_id(cov_name, level_name));

colorRate = 1;
orientRate = 5;
ruleRatio = orientRate / colorRate;

Rate(level_ind('Rule', 'Color')) = colorRate;
Rate(level_ind('Rule', 'Orientation')) = orientRate;

% Correct Model
model = 'Rule';
[saveDir, spikes] = testComputeGAMfit_wrapper(model, Rate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, ...
    'isPrediction', true);

correct = load(sprintf('%s/Test_neuron_test_1_1_GAMpred.mat', saveDir), 'neuron');

% Misspecified Model
model = 'Response Direction';
[saveDir, spikes] = testComputeGAMfit_wrapper(model, Rate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, ...
    'isPrediction', true, 'spikes', spikes);

misspecified = load(sprintf('%s/Test_neuron_test_1_1_GAMpred.mat', saveDir), 'neuron');


%% Plot
figure;

% AUC
subplot(1,3,1);
meanPredError = mean([correct.neuron.AUC; misspecified.neuron.AUC], 2);
plot(1:2, meanPredError)
set(gca, 'XTick', 1:2)
set(gca, 'XTickLabel', {'Correct Model', 'Misspecified Model'})
hline(0.5, 'Color', 'black');
title('AUC')

% MI
subplot(1,3,2);
meanPredError = mean([correct.neuron.mutualInformation; misspecified.neuron.mutualInformation], 2);
plot(1:2, meanPredError)
set(gca, 'XTick', 1:2)
set(gca, 'XTickLabel', {'Correct Model', 'Misspecified Model'})
hline(0.0, 'Color', 'black');
title('Mutual Information (bits / spike)')

% Deviance
subplot(1,3,3);
meanPredError = mean([correct.neuron.Dev; misspecified.neuron.Dev], 2);
plot(1:2, meanPredError)
set(gca, 'XTick', 1:2)
set(gca, 'XTickLabel', {'Correct Model', 'Misspecified Model'})
title('Deviance (Smaller is Better)')