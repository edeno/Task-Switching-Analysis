clear all; close all; clc;
cd('C:\Users\edeno\Documents\MATLAB');
load('behavior.mat');
load('cc1_GLMCov.mat', 'GLMCov');

monkey = cat(1, behavior.monkey);
isCC = ismember(monkey, 'CC');
isCH = ismember(monkey, 'CH');
isISA = ismember(monkey, 'ISA');

%% Reaction Time
Reaction_Time = cat(1, behavior.Reaction_Time);

% Covariates
Rule = dummyvar(cat(1, behavior.Rule));
Switch = dummyvar(cat(1, behavior.Switch));
Rule_Repetition = dummyvar(cat(1, behavior.Rule_Repetition));
Previous_Error = dummyvar(cat(1, behavior.Previous_Error));
Congruency_History = dummyvar(cat(1, behavior.Congruency_History));
Preparation_Time = dummyvar(cat(1, behavior.Indicator_Prep_Time));
Response_Direction = dummyvar(cat(1, behavior.Response_Direction));

% Drop level
rule_ind = 2;
Rule = Rule(:, rule_ind);
switch_ind = 2;
Switch = Switch(:, switch_ind);
rule_rep_ind = 1:10;
Rule_Repetition = Rule_Repetition(:, rule_rep_ind);
prev_error_ind = 2;
Previous_Error = Previous_Error(:, prev_error_ind);
con_hist_ind = [2,4];
Congruency_History = Congruency_History(:, con_hist_ind);
prep_ind = [1:2, 4:5];
Preparation_Time = Preparation_Time(:, prep_ind);
response_ind = 2;
Response_Direction = Response_Direction(:, response_ind);

% Create Design Matrix
designMatrix = [Rule, Rule_Repetition, Previous_Error, Congruency_History, Preparation_Time, Response_Direction];
level_names = [GLMCov(ismember({GLMCov.name}, 'Rule')).levels(rule_ind), ...
    GLMCov(ismember({GLMCov.name}, 'Rule Repetition')).levels(rule_rep_ind), ...
    GLMCov(ismember({GLMCov.name}, 'Previous Error')).levels(prev_error_ind), ...
    GLMCov(ismember({GLMCov.name}, 'Congruency History')).levels(con_hist_ind), ...
    GLMCov(ismember({GLMCov.name}, 'Indicator Prep Time')).levels(prep_ind), ...
    GLMCov(ismember({GLMCov.name}, 'Response Direction')).levels(response_ind)];

% Fit Model
coef_CC = glmfit(designMatrix(isCC, :), Reaction_Time(isCC, :), 'normal', 'link', 'log');
coef_CH = glmfit(designMatrix(isCH, :), Reaction_Time(isCH, :), 'normal', 'link', 'log');
coef_ISA = glmfit(designMatrix(isISA, :), Reaction_Time(isISA, :), 'normal', 'link', 'log');

figure;
plot(100*(exp(coef_CC(end:-1:2)) - 1), 1:length(level_names), '--o'); hold all;
plot(100*(exp(coef_ISA(end:-1:2)) - 1), 1:length(level_names), '--o');
plot(100*(exp(coef_CH(end:-1:2)) - 1), 1:length(level_names), '--o');
vline(0, 'k');
set(gca, 'YTick', 1:length(level_names))
set(gca, 'YTickLabel', level_names(end:-1:1))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Reaction Time');
xlim([-60 60]);
box off;
text(3,0,'Increase in Reaction Time (%) \rightarrow')
text(-3,0,'\leftarrow Decrease in Reaction Time (%)', 'HorizontalAlignment','right')
grid on;
%% Reaction Time - log scale
figure;
plot(coef_CC(end:-1:2), 1:length(level_names), '--o'); hold all;
plot(coef_ISA(end:-1:2), 1:length(level_names), '--o');
plot(coef_CH(end:-1:2), 1:length(level_names), '--o');
vline(0, 'k');
set(gca, 'YTick', 1:length(level_names))
set(gca, 'YTickLabel', level_names(end:-1:1))
set(gca, 'YTick', 1:length(level_names))
set(gca, 'YTickLabel', level_names(end:-1:1))
set(gca, 'XAxisLocation', 'top')
xlim(log([0.6, 1.6]))
set(gca, 'XTick', log(0.6:0.1:1.6))
set(gca, 'XTickLabel', -40:10:60)
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Reaction Time');

box off;
text(3,0,'Increase in Reaction Time (%) \rightarrow')
text(-3,0,'\leftarrow Decrease in Reaction Time (%)', 'HorizontalAlignment','right')
grid on;
%% Percent Correct
Correct = double(cat(1, behavior.correct));

% Fit Model
coef_CC = glmfit(designMatrix(isCC, :), Correct(isCC, :),'binomial','link','logit');
coef_CH = glmfit(designMatrix(isCH, :), Correct(isCH, :),'binomial','link','logit');
coef_ISA = glmfit(designMatrix(isISA, :), Correct(isISA, :),'binomial','link','logit');

figure;
plot(100*(exp(coef_CC(end:-1:2)) - 1), 1:length(level_names), '--o'); hold all;
plot(100*(exp(coef_ISA(end:-1:2)) - 1), 1:length(level_names), '--o');
plot(100*(exp(coef_CH(end:-1:2)) - 1), 1:length(level_names), '--o');
vline(0, 'k');
set(gca, 'YTick', 1:length(level_names))
set(gca, 'YTickLabel', level_names(end:-1:1))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Odds of Correct Response');
xlim([-100 250]);
box off;
text(3,0,'Increase in Odds of Correct Response \rightarrow')
text(-3,0,'\leftarrow Decrease in Odds of Correct Response', 'HorizontalAlignment','right')
grid on;
%% Incorrect/Correct - log scale
figure;
plot(coef_CC(end:-1:2), 1:length(level_names), '--o'); hold all;
plot(coef_ISA(end:-1:2), 1:length(level_names), '--o');
plot(coef_CH(end:-1:2), 1:length(level_names), '--o');
vline(0, 'k');
set(gca, 'YTick', 1:length(level_names))
set(gca, 'YTickLabel', level_names(end:-1:1))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Odds of Correct Response');
xlim(log([0.05, 9.5]))
set(gca, 'XTick', log(0.5:0.5:9.5))
set(gca, 'XTickLabel', -50:50:950)
box off;
text(0.01,0,'Increase in Odds of Correct Response \rightarrow')
text(-0.01,0,'\leftarrow Decrease in Odds of Correct Response', 'HorizontalAlignment','right')
grid on;

