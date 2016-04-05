clear variables; close all; clc; profile off;

% GAMpred parameters
numFolds = 1;
isOverwrite = true;
ridgeLambda = 0;
smoothLambda = 0;

% Simulate Session
numTrials = 2000;
[spikeCov, trial_time, isCorrect, isAttempted, trial_id] = simSession(numTrials);

% Load Common Parameters
mainDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', mainDir), 'covInfo');

trueRate = nan(size(trial_time));

cov_id = @(cov_name, level_name) find(ismember(covInfo(cov_name).levels, level_name));
level_ind = @(cov_name, level_name) ismember(spikeCov(cov_name), cov_id(cov_name, level_name));

%% Orientation Interaction -- Boosting Orientation Rate on Switch Trials
colorRate = 10;
orientRate = 50;

trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition1')) = colorRate * 2;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition2')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition3')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition4')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition5+')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition1')) = orientRate * 2 * 3;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition2')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition3')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition4')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition5+')) = orientRate;


model = 'Rule * Rule Repetition';
saveDir = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

load(sprintf('%s/Test_neuron_test_1_1_GAMfit.mat', saveDir), 'neuron', 'stat');
load(sprintf('%s/test_GAMfit.mat', saveDir), 'gamParams', 'designMatrix', 'gam');

orient_ind = ismember(gam.levelNames, {'Orientation', 'Orientation:Repetition1'});

fprintf('\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(neuron.parEst(orient_ind)));
fprintf('\nABS----\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(abs(neuron.parEst(orient_ind))));
%% Orientation Interaction -- Orientation Rate on Switch trials goes down
colorRate = 10;
orientRate = 50;

trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition1')) = colorRate * 2;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition2')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition3')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition4')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition5+')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition1')) = orientRate * 2 * .5;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition2')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition3')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition4')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition5+')) = orientRate;


model = 'Rule * Rule Repetition';
saveDir = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

load(sprintf('%s/Test_neuron_test_1_1_GAMfit.mat', saveDir), 'neuron', 'stat');
load(sprintf('%s/test_GAMfit.mat', saveDir), 'gamParams', 'designMatrix', 'gam');

orient_ind = ismember(gam.levelNames, {'Orientation', 'Orientation:Repetition1'});

fprintf('\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(neuron.parEst(orient_ind)));
fprintf('\nABS----\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(abs(neuron.parEst(orient_ind))));
%% Color Interaction -- Boosting Color Rate on Switch Trials
colorRate = 50;
orientRate = 10;

trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition1')) = colorRate * 2  * 3;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition2')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition3')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition4')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition5+')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition1')) = orientRate * 2;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition2')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition3')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition4')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition5+')) = orientRate;


model = 'Rule * Rule Repetition';
saveDir = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

load(sprintf('%s/Test_neuron_test_1_1_GAMfit.mat', saveDir), 'neuron', 'stat');
load(sprintf('%s/test_GAMfit.mat', saveDir), 'gamParams', 'designMatrix', 'gam');

orient_ind = ismember(gam.levelNames, {'Orientation', 'Orientation:Repetition1'});

fprintf('\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(neuron.parEst(orient_ind)));
fprintf('\nABS----\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(abs(neuron.parEst(orient_ind))));
%% Color Interaction -- Color Rate goes down on Switch Trials
colorRate = 50;
orientRate = 10;

trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition1')) = colorRate * 2  * .5;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition2')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition3')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition4')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition5+')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition1')) = orientRate * 2;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition2')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition3')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition4')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition5+')) = orientRate;


model = 'Rule * Rule Repetition';
saveDir = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

load(sprintf('%s/Test_neuron_test_1_1_GAMfit.mat', saveDir), 'neuron', 'stat');
load(sprintf('%s/test_GAMfit.mat', saveDir), 'gamParams', 'designMatrix', 'gam');

orient_ind = ismember(gam.levelNames, {'Orientation', 'Orientation:Repetition1'});

fprintf('\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(neuron.parEst(orient_ind)));
fprintf('\nABS----\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(abs(neuron.parEst(orient_ind))));

%% No interaction, just boost on color trials
colorRate = 50;
orientRate = 10;

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


model = 'Rule * Rule Repetition';
saveDir = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

load(sprintf('%s/Test_neuron_test_1_1_GAMfit.mat', saveDir), 'neuron', 'stat');
load(sprintf('%s/test_GAMfit.mat', saveDir), 'gamParams', 'designMatrix', 'gam');

orient_ind = ismember(gam.levelNames, {'Orientation', 'Orientation:Repetition1'});

fprintf('\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(neuron.parEst(orient_ind)));
fprintf('\nABS----\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(abs(neuron.parEst(orient_ind))));

%% No interaction, just boost on orientation trials
colorRate = 10;
orientRate = 50;

trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition1')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition2')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition3')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition4')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition5+')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition1')) = orientRate  * 2;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition2')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition3')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition4')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition5+')) = orientRate;


model = 'Rule * Rule Repetition';
saveDir = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

load(sprintf('%s/Test_neuron_test_1_1_GAMfit.mat', saveDir), 'neuron', 'stat');
load(sprintf('%s/test_GAMfit.mat', saveDir), 'gamParams', 'designMatrix', 'gam');

orient_ind = ismember(gam.levelNames, {'Orientation', 'Orientation:Repetition1'});

fprintf('\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(neuron.parEst(orient_ind)));
fprintf('\nABS----\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(abs(neuron.parEst(orient_ind))));

%%
colorRate = 1;
orientRate = 2;

trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition1')) = colorRate * 2;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition2')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition3')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition4')) = colorRate;
trueRate(level_ind('Rule', 'Color') & level_ind('Rule Repetition', 'Repetition5+')) = colorRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition1')) = orientRate  * 2 * 3;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition2')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition3')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition4')) = orientRate;
trueRate(level_ind('Rule', 'Orientation') & level_ind('Rule Repetition', 'Repetition5+')) = orientRate;


model = 'Rule * Rule Repetition';
saveDir = testComputeGAMfit_wrapper(model, trueRate, ...
    'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'smoothLambda', smoothLambda, ...
    'isPrediction', false);

load(sprintf('%s/Test_neuron_test_1_1_GAMfit.mat', saveDir), 'neuron', 'stat');
load(sprintf('%s/test_GAMfit.mat', saveDir), 'gamParams', 'designMatrix', 'gam');

orient_ind = ismember(gam.levelNames, {'Orientation', 'Orientation:Repetition1'});

fprintf('\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(neuron.parEst(orient_ind)));
fprintf('\nABS----\nOrientation Rep5+: %.1f\nOrientation Rep1: %.1f\n', exp(abs(neuron.parEst(orient_ind))));
