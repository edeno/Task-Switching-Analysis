%% Binary Categorical Covariate - Rule
clear all; close all; clc;
numTrials = 2000;
[GLMCov, trial_id, trial_time, incorrect] = simSession(numTrials);

Rate = nan(size(trial_time));

cov_ind = @(cov_name) ismember({GLMCov.name}, cov_name);
cov_id = @(cov_name, level_name) find(ismember(GLMCov(cov_ind(cov_name)).levels, level_name));
level_ind = @(cov_name, level_name) ismember(GLMCov(cov_ind(cov_name)).data, cov_id(cov_name, level_name));

colorRate = 3;
orientRate = 12;
ruleRatio = orientRate / colorRate;

Rate(level_ind('Rule', 'Color')) = colorRate;
Rate(level_ind('Rule', 'Orientation')) = orientRate;

Intercept = geomean([colorRate orientRate]);
color_param = colorRate/Intercept;
orient_param = orientRate/Intercept;

model_name = 'Rule';
[par_est, fitInfo] = estGAMParam(Rate, GLMCov, model_name, trial_id, incorrect);

est_Intercept = exp(par_est(1))*1000;
est_Orient = exp(par_est(2));
est_Color = exp(par_est(3));
est_ruleRatio = est_Orient/est_Color;

fprintf('\n True Intercept: %6.2f \t Est Intercept: %6.2f\n', Intercept, est_Intercept)
fprintf('\n True Orientation: %6.2f \t Est Orientation: %6.2f\n', orient_param, est_Orient)
fprintf('\n True Color: %6.2f \t Est Color: %6.2f\n', color_param, est_Color)
fprintf('\n True Rule Ratio: %6.2f \t Est Rule Ratio: %6.2f\n', ruleRatio, est_ruleRatio)
fprintf('--------------------------------------------------------');

%% Multilevel Categorical Covariate - Switch History

Rate = nan(size(trial_time));

cov_ind = @(cov_name) ismember({GLMCov.name}, cov_name);
cov_id = @(cov_name, level_name) find(ismember(GLMCov(cov_ind(cov_name)).levels, level_name));
level_ind = @(cov_name, level_name) ismember(GLMCov(cov_ind(cov_name)).data, cov_id(cov_name, level_name));

repRate = [12 6 4 3 2 1 1 1 1 1 6];

Rate(level_ind('Switch History', 'Repetition1')) = repRate(1);
Rate(level_ind('Switch History', 'Repetition2')) = repRate(2);
Rate(level_ind('Switch History', 'Repetition3')) = repRate(3);
Rate(level_ind('Switch History', 'Repetition4')) = repRate(4);
Rate(level_ind('Switch History', 'Repetition5')) = repRate(5);
Rate(level_ind('Switch History', 'Repetition6')) = repRate(6);
Rate(level_ind('Switch History', 'Repetition7')) = repRate(7);
Rate(level_ind('Switch History', 'Repetition8')) = repRate(8);
Rate(level_ind('Switch History', 'Repetition9')) = repRate(9);
Rate(level_ind('Switch History', 'Repetition10')) = repRate(10);
Rate(level_ind('Switch History', 'Repetition11+')) = repRate(11);

Intercept = geomean(repRate);
repRate_param = repRate/Intercept;

model_name = 'Switch History';
[par_est, fitInfo] = estGAMParam(Rate, GLMCov, model_name, trial_id, incorrect);

est_Intercept = exp(par_est(1))*1000;
est_repRate = exp(par_est(2:end));

fprintf('\n True Intercept: %6.2f \t Est Intercept: %6.2f\n', Intercept, est_Intercept)
for k = 1:11,
    fprintf('\n True Repetition: %6.2f \t Est Repetition: %6.2f\n', repRate_param(k), est_repRate(k))
end

%% Two Covariates - Rule and Switch History