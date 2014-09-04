clear all; close all; clc;
numTrials = 2000;
[GLMCov, trial_id, trial_time, incorrect] = simSession(numTrials);
%% Binary Categorical Covariate - Rule
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
[par_est, fitInfo, gam, designMatrix] = estGAMParam(Rate, GLMCov, model_name, trial_id, incorrect);

est_Intercept = exp(par_est(1))*1000;
est_Orient = exp(par_est(2));
est_Color = exp(par_est(3));
est_ruleRatio = est_Orient/est_Color;

fprintf('\n True Intercept: %6.2f \t Est Intercept: %6.2f\n', Intercept, est_Intercept)
fprintf('\n True Orientation: %6.2f \t Est Orientation: %6.2f\n', orient_param, est_Orient)
fprintf('\n True Color: %6.2f \t Est Color: %6.2f\n', color_param, est_Color)
fprintf('\n True Rule Ratio: %6.2f \t Est Rule Ratio: %6.2f\n', ruleRatio, est_ruleRatio)
fprintf('--------------------------------------------------------');

figure;
plot(exp(designMatrix * par_est)*1000, 'LineWidth', 2)
hold all;
plot(Rate(~incorrect), 'LineWidth', 2)
legend('Estimated Rate', 'True Rate');
title('Rule');
box off;
%% Multilevel Categorical Covariate - Switch History

Rate = nan(size(trial_time));
trueInterceptRate = 4;
trueSwitch = [2.0 2.0 2.0 2.0 2.0 1.0 0.5 0.5 0.5 0.5 0.5];
trueParams = log([(trueInterceptRate*1E-3) trueSwitch])';

model_name = 'Switch History';

designMatrix = gamModelMatrix(model_name, GLMCov, Rate);
Rate = exp(designMatrix * trueParams)*1000;

% repRate = [12 6 4 3 2 1 1 1 1 1 6];
%
% Rate(level_ind('Switch History', 'Repetition1')) = repRate(1);
% Rate(level_ind('Switch History', 'Repetition2')) = repRate(2);
% Rate(level_ind('Switch History', 'Repetition3')) = repRate(3);
% Rate(level_ind('Switch History', 'Repetition4')) = repRate(4);
% Rate(level_ind('Switch History', 'Repetition5')) = repRate(5);
% Rate(level_ind('Switch History', 'Repetition6')) = repRate(6);
% Rate(level_ind('Switch History', 'Repetition7')) = repRate(7);
% Rate(level_ind('Switch History', 'Repetition8')) = repRate(8);
% Rate(level_ind('Switch History', 'Repetition9')) = repRate(9);
% Rate(level_ind('Switch History', 'Repetition10')) = repRate(10);
% Rate(level_ind('Switch History', 'Repetition11+')) = repRate(11);
%
% Intercept = geomean(repRate);
% repRate_param = repRate/Intercept;


[par_est, fitInfo, gam, designMatrix] = estGAMParam(Rate, GLMCov, model_name, trial_id, incorrect);

% est_Intercept = exp(par_est(1))*1000;
% est_repRate = exp(par_est(2:end));
%
% fprintf('\n True Intercept: %6.2f \t Est Intercept: %6.2f\n', Intercept, est_Intercept)
% for k = 1:11,
%     fprintf('\n True Repetition: %6.2f \t Est Repetition: %6.2f\n', repRate_param(k), est_repRate(k))
% end
% fprintf('--------------------------------------------------------');

figure;
plot(Rate(~incorrect), 'LineWidth', 2)
hold all;
plot(exp(designMatrix * par_est)*1000, 'LineWidth', 2)
legend('True Rate', 'Estimated Rate');
title('Switch History');
box off;
exp([trueParams par_est])

%% Two Covariates - Rule + Switch History
model_name = 'Rule + Switch History';
Rate = nan(size(trial_time));

trueInterceptRate = 4;
trueRule = [0.5 (0.5)^(-1)];
trueSwitch = [3.0 2.5 1.0 0.5 0.25 0.25 0.25 0.25 0.25 0.25 2.5];
trueParams = log([(trueInterceptRate*1E-3) trueRule trueSwitch])';

designMatrix = gamModelMatrix(model_name, GLMCov, Rate);
Rate = exp(designMatrix * trueParams)*1000;

[par_est, fitInfo, gam, designMatrix] = estGAMParam(Rate, GLMCov, model_name, trial_id, incorrect);

figure;
plot(Rate(~incorrect), 'LineWidth', 2)
hold all;
plot(exp(designMatrix * par_est)*1000, 'LineWidth', 2)
legend('Estimated Rate', 'True Rate');
title('Rule + Switch History');

exp([trueParams par_est])

%% Interactions

model_name = 'Rule * Response Direction';
Rate = nan(size(trial_time));

rule_ind = ismember({GLMCov.name}, 'Rule');
response_ind = ismember({GLMCov.name}, 'Response Direction');

% Try to use rates (as opposed to defining coefficients)
% Orientation - Right
Rate((GLMCov(rule_ind).data == 1) & (GLMCov(response_ind).data == 1)) = 20;
% Orientation - Left
Rate((GLMCov(rule_ind).data == 1) & (GLMCov(response_ind).data == 2)) = 40;
% Color - Right
Rate((GLMCov(rule_ind).data == 2) & (GLMCov(response_ind).data == 1)) = 60;
% Color - Left
Rate((GLMCov(rule_ind).data == 2) & (GLMCov(response_ind).data == 2)) = 180;

[par_est, fitInfo, gam, designMatrix] = estGAMParam(Rate, GLMCov, model_name, trial_id, incorrect);

abs_pct_change = @(x) exp(abs(diff(x)));

[par_est exp(par_est)]

cr = sum(par_est(ismember(gam.level_names, {'Color', 'Right', 'Color:Right'})));
or = sum(par_est(ismember(gam.level_names, {'Orientation', 'Right', 'Orientation:Right'})));
cl = sum(par_est(ismember(gam.level_names, {'Color', 'Left', 'Color:Left'})));
ol = sum(par_est(ismember(gam.level_names, {'Orientation', 'Left', 'Orientation:Left'})));


% Intercept
fprintf('\nestimated grand mean: %.2f \t true grand mean: %.2f\n', exp(par_est(1))*1000, geomean([20 40 60 180]))
% Rule - Right
fprintf('\nestimated rule-right: %.2f \t true rule-right: %.2f\n', abs_pct_change([cr or]), abs_pct_change(log([60 20])))
% Rule - Left
fprintf('\nrule-left: %.2f \t true rule-left: %.2f\n', abs_pct_change([cl ol]), abs_pct_change(log([180 40])))

% Try to define coefficients
%
% trueParams = log([(20/1000) 3 (1/3) 2 (1/2) 1.3 1 1 (1.3)])';
% designMatrix = gamModelMatrix(model_name, GLMCov, Rate);
% Rate = exp(designMatrix * trueParams)*1000;
%
% [par_est, fitInfo, gam, designMatrix] = estGAMParam(Rate, GLMCov, model_name, trial_id, incorrect);

%% Two Interactions

model_name = 'Rule * Response Direction + Rule * Switch History';
Rate = nan(size(trial_time));

rule_ind = ismember({GLMCov.name}, 'Rule');
response_ind = ismember({GLMCov.name}, 'Response Direction');
switch_ind = ismember({GLMCov.name}, 'Switch History');

orient_ind = (GLMCov(rule_ind).data == 1);
color_ind = (GLMCov(rule_ind).data == 2);
right_ind = (GLMCov(response_ind).data == 1);
left_ind = (GLMCov(response_ind).data == 2);

Rate(:) = 2;
Rate(color_ind) = Rate(color_ind) * 3;
Rate(left_ind) = Rate(left_ind) * 2;

Rate(color_ind & left_ind) = Rate(color_ind & left_ind) * 1.5;
switch_effect = linspace(1.5, 0.5, 11);
for n = 1:11,
    Rate(GLMCov(switch_ind).data == n) =  Rate(GLMCov(switch_ind).data == n) * switch_effect(n);
end

Rate(GLMCov(switch_ind).data == 1) = Rate(GLMCov(switch_ind).data == 1) * 1.5;

[par_est, fitInfo, gam, designMatrix] = estGAMParam(Rate, GLMCov, model_name, trial_id, incorrect);

cr = sum(par_est(ismember(gam.level_names, {'Color', 'Right', 'Color:Right'})));
or = sum(par_est(ismember(gam.level_names, {'Orientation', 'Right', 'Orientation:Right'})));
cl = sum(par_est(ismember(gam.level_names, {'Color', 'Left', 'Color:Left'})));
ol = sum(par_est(ismember(gam.level_names, {'Orientation', 'Left', 'Orientation:Left'})));

% Intercept
fprintf('\nestimated grand mean: %.2f \t true grand mean: %.2f\n', exp(par_est(1))*1000, geomean(unique(Rate)))
% Rule - Right
fprintf('\nestimated rule-right: %.2f \t true rule-right: %.2f\n', abs_pct_change([cr or]), abs_pct_change(log([6 2])))
% Rule - Left
fprintf('\nrule-left: %.2f \t true rule-left: %.2f\n', abs_pct_change([cl ol]), abs_pct_change(log([18 4])))
% Rule - Switch History
for n = 1:10,
    sw_color = sum(par_est(ismember(gam.level_names, {'Color', ['Repetition',  num2str(n)], ['Color:Repetition',  num2str(n)]})));
    sw_orient = sum(par_est(ismember(gam.level_names, {'Orientation', ['Repetition',  num2str(n)], ['Orientation:Repetition',  num2str(n)]})));
    fprintf('\nestimated rule-switch: %.2f \t true rule-switch: %.2f\n', abs_pct_change([sw_color sw_orient]), 1)
end

sw_color = sum(par_est(ismember(gam.level_names, {'Color', 'Repetition11+', 'Color:Repetition11+'})));
sw_orient = sum(par_est(ismember(gam.level_names, {'Orientation', 'Repetition11+', 'Orientation:Repetition11+'})));
fprintf('\nestimated rule-switch: %.2f \t true rule-switch: %.2f\n', abs_pct_change([sw_color sw_orient]), 1)

