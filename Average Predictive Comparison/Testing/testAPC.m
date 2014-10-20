clear all; close all; clc;
% Set Parameters for GLMCov
numTrials = 2000;
main_dir = 'C:\Users\edeno\Documents\Task Switching Testing';

[GLMCov_name, timePeriod_dir, session_name] = create_testGLMCov(main_dir, numTrials);
load(GLMCov_name);

% Set Parameters for GAMfit
gamParams.includeIncorrect = false;
gamParams.includeBeforeTimeZero = false;
gamParams.regressionModel_str = 'Rule';
gamParams.overwrite = true;
gamParams.numFolds = 1;
gamParams.ridgeLambda = 1;
gamParams.smoothLambda = 1;
gamParams.predType = 'Dev';
%%
Rate = nan(size(trial_time));

cov_ind = @(cov_name) ismember({GLMCov.name}, cov_name);
cov_id = @(cov_name, level_name) find(ismember(GLMCov(cov_ind(cov_name)).levels, level_name));
level_ind = @(cov_name, level_name) ismember(GLMCov(cov_ind(cov_name)).data, cov_id(cov_name, level_name));

colorRate = 3;
orientRate = 12;

Rate(level_ind('Rule', 'Color')) = colorRate;
Rate(level_ind('Rule', 'Orientation')) = orientRate;

% Estimate GAMfit
[neurons, gam, designMatrix, spikes, model_dir] = testComputeGAMfit_wrapper(gamParams, Rate, GLMCov_name, timePeriod_dir, session_name);

% Set Parameters for APC
numSim = 5000;
numSamples = 1000;
timePeriod = 'timePeriod';
factor_name = 'Rule';

[avpred] = testAvrPredComp_wrapper(model_dir, gamParams, factor_name, session_name, timePeriod, numSim, numSamples, main_dir);