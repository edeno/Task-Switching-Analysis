%% Test APC
clear all; close all; clc;
% Set Parameters
numTrials = 2000;
numSim = 5000;
numSamples = 2000;
gamParams.includeIncorrect = false;
gamParams.includeBeforeTimeZero = false;

% Create Folders
timePeriod = 'timePeriod';
session_name = 'session_name';
main_dir = 'C:\Users\edeno\Documents\Task Switching Testing';

data_info.processed_dir = [main_dir, '/Processed Data'];
timePeriod_dir = [data_info.processed_dir, '/', timePeriod];
models_dir = [timePeriod_dir, '/Models'];
GLMCov_dir = [timePeriod_dir, '/GLMCov'];

mkdir(data_info.processed_dir);
mkdir(timePeriod_dir);
mkdir(models_dir);
mkdir(GLMCov_dir);
save([main_dir, '/paramSet.mat'], 'data_info');

[GLMCov, trial_id, trial_time, incorrect] = simSession(numTrials);
%% Binary Categorical Covariate - Rule
Rate = nan(size(trial_time));

cov_ind = @(cov_name) ismember({GLMCov.name}, cov_name);
cov_id = @(cov_name, level_name) find(ismember(GLMCov(cov_ind(cov_name)).levels, level_name));
level_ind = @(cov_name, level_name) ismember(GLMCov(cov_ind(cov_name)).data, cov_id(cov_name, level_name));

colorRate = 3;
orientRate = 12;

Rate(level_ind('Rule', 'Color')) = colorRate;
Rate(level_ind('Rule', 'Orientation')) = orientRate;

gamParams.regressionModel_str = 'Rule';
model_dir = [models_dir, '/', gamParams.regressionModel_str];
mkdir(model_dir);
[neurons, gam, designMatrix, spikes] = estGAMParam(Rate, GLMCov, gamParams.regressionModel_str, trial_id, incorrect);
numNeurons = length(neurons);
save([GLMCov_dir, '/', session_name, '_GLMCov.mat'], 'GLMCov', 'trial_id', 'trial_time', 'incorrect', 'spikes');
save([models_dir, '/', gamParams.regressionModel_str, '/', session_name, '_GAMfit.mat'], 'gam', 'gamParams', 'neurons', 'numNeurons', 'designMatrix');

apc_dir = [models_dir, '/', gamParams.regressionModel_str, '/APC'];
factor_name = 'Rule';
save_folder = [apc_dir, '/', factor_name, '/'];
mkdir(save_folder);

[avpred] = avrPredComp(session_name, timePeriod, gamParams.regressionModel_str, factor_name, numSim, numSamples, save_folder, main_dir);
mean(avpred.apc)
quantile(avpred.apc, [.025 .975])