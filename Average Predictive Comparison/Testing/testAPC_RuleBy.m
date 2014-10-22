clear all; close all; clc;

% Set Parameters for GLMCov
numTrials = 2000;
drop_path = getappdata(0, 'drop_path');
main_dir = sprintf('%s/Task Switching Testing', drop_path);

[GLMCov_name, timePeriod_dir, session_name] = create_testGLMCov(main_dir, numTrials);
load(GLMCov_name);

% Helper Functions
cov_ind = @(cov_name) ismember({GLMCov.name}, cov_name);
cov_id = @(cov_name, level_name) find(ismember(GLMCov(cov_ind(cov_name)).levels, level_name));
level_ind = @(cov_name, level_name) ismember(GLMCov(cov_ind(cov_name)).data, cov_id(cov_name, level_name));

% Set Parameters for GAMfit
gamParams.includeIncorrect = false;
gamParams.includeBeforeTimeZero = false;
gamParams.overwrite = true;
gamParams.numFolds = 1;
gamParams.ridgeLambda = 1;
gamParams.smoothLambda = 1;
gamParams.predType = 'Dev';

% Set General APC Parameters
numSim = 5000;
numSamples = 1000;
timePeriod = 'timePeriod';

%% Two Covariates - Rule + Response Direction
gamParams.regressionModel_str = 'Rule + Response Direction';
Rate = nan(size(trial_time));

% Orientation - Right
Rate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Right')) = 2;
% Orientation - Left
Rate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Left')) = 4;
% Color - Right
Rate(level_ind('Rule', 'Color') & level_ind('Response Direction', 'Right')) = 6;
% Color - Left
Rate(level_ind('Rule', 'Color') & level_ind('Response Direction', 'Left')) = 12;

% Estimate GAMfit
[neurons, gam, designMatrix, spikes, model_dir] = testComputeGAMfit_wrapper(gamParams, Rate, GLMCov_name, timePeriod_dir, session_name);

% Set Parameters for APC

factor_name = 'Response Direction';
[avpred] = testAvrPredComp_RuleBy_wrapper(model_dir, gamParams, factor_name, session_name, timePeriod, numSim, numSamples, main_dir);
mean(avpred.apc, 2)'
diffRate = [20 - 60, 40 - 120]
%% Two Covariates - Rule + Response Direction: Mispecified Model
gamParams.regressionModel_str = 'Rule + Response Direction';
Rate = nan(size(trial_time));

colorRate = 3;
orientRate = 12;

Rate(level_ind('Rule', 'Color')) = colorRate;
Rate(level_ind('Rule', 'Orientation')) = orientRate;

% Estimate GAMfit
[neurons, gam, designMatrix, spikes, model_dir] = testComputeGAMfit_wrapper(gamParams, Rate, GLMCov_name, timePeriod_dir, session_name);

% Set Parameters for APC
factor_name = 'Response Direction';
[avpred] = testAvrPredComp_RuleBy_wrapper(model_dir, gamParams, factor_name, session_name, timePeriod, numSim, numSamples, main_dir);
mean(avpred.apc, 2)'
diffRate = [orientRate - colorRate, orientRate - colorRate]

%% Two Covariates Interaction - Rule * Response Direction
gamParams.regressionModel_str = 'Rule * Response Direction';
Rate = nan(size(trial_time));

% Orientation - Right
Rate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Right')) = 2;
% Orientation - Left
Rate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Left')) = 4;
% Color - Right
Rate(level_ind('Rule', 'Color') & level_ind('Response Direction', 'Right')) = 6;
% Color - Left
Rate(level_ind('Rule', 'Color') & level_ind('Response Direction', 'Left')) = 18;

% Estimate GAMfit
[neurons, gam, designMatrix, spikes, model_dir] = testComputeGAMfit_wrapper(gamParams, Rate, GLMCov_name, timePeriod_dir, session_name);

% Set Parameters for APC
factor_name = 'Response Direction';
[avpred] = testAvrPredComp_RuleBy_wrapper(model_dir, gamParams, factor_name, session_name, timePeriod, numSim, numSamples, main_dir);
mean(avpred.apc, 2)'
diffRate = [2 - 6, 4 - 18]

%% Two Covariates Interaction - Rule * Response Direction: Mispecified Model
gamParams.regressionModel_str = 'Rule * Response Direction';
Rate = nan(size(trial_time));

% Orientation - Right
Rate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Right')) = 2;
% Orientation - Left
Rate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Left')) = 4;
% Color - Right
Rate(level_ind('Rule', 'Color') & level_ind('Response Direction', 'Right')) = 6;
% Color - Left
Rate(level_ind('Rule', 'Color') & level_ind('Response Direction', 'Left')) = 12;

% Estimate GAMfit
[neurons, gam, designMatrix, spikes, model_dir] = testComputeGAMfit_wrapper(gamParams, Rate, GLMCov_name, timePeriod_dir, session_name);

% Set Parameters for APC
factor_name = 'Response Direction';
[avpred] = testAvrPredComp_RuleBy_wrapper(model_dir, gamParams, factor_name, session_name, timePeriod, numSim, numSamples, main_dir);
mean(avpred.apc, 2)'
diffRate = [2 - 6, 4 - 12]

%% Two Covariates Interaction + Other Covariate - Rule * Response Direction + Switch History
gamParams.regressionModel_str = 'Rule * Response Direction + Switch History';
Rate = nan(size(trial_time));

% Orientation - Right
Rate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Right')) = 2;
% Orientation - Left
Rate(level_ind('Rule', 'Orientation') & level_ind('Response Direction', 'Left')) = 4;
% Color - Right
Rate(level_ind('Rule', 'Color') & level_ind('Response Direction', 'Right')) = 6;
% Color - Left
Rate(level_ind('Rule', 'Color') & level_ind('Response Direction', 'Left')) = 18;

trueSwitch = [4.0 2.0 1.0 1.0 1.0 2.0 1.0 1.0 1.0 1.0 0.0];
for rep_ind = 1:10,
    idx = level_ind('Switch History', ['Repetition', num2str(rep_ind)]);
    Rate(idx) = Rate(idx) + trueSwitch(rep_ind);
end
idx = level_ind('Switch History', 'Repetition11+');
Rate(idx) = Rate(idx) + trueSwitch(11);

% Estimate GAMfit
[neurons, gam, designMatrix, spikes, model_dir] = testComputeGAMfit_wrapper(gamParams, Rate, GLMCov_name, timePeriod_dir, session_name);

% Set Parameters for APC
factor_name = 'Response Direction';
[avpred] = testAvrPredComp_RuleBy_wrapper(model_dir, gamParams, factor_name, session_name, timePeriod, numSim, numSamples, main_dir);
diffRate = [2-6, 4-18]
mean(avpred.apc, 2)'

factor_name = 'Switch History';
[avpred] = testAvrPredComp_wrapper(model_dir, gamParams, factor_name, session_name, timePeriod, numSim, numSamples, main_dir);
mean(avpred.apc, 2)'
