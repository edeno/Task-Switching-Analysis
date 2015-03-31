clear all; close all; clc;
cd('C:\Users\edeno\Documents\MATLAB');
load('behavior.mat');
load('cc1_GLMCov.mat', 'GLMCov');

monkey = cat(1, behavior.monkey);
isCC = ismember(monkey, 'CC');
isCH = ismember(monkey, 'CH');
isISA = ismember(monkey, 'ISA');

%% Model

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
designMatrix = [Rule, Rule_Repetition, Previous_Error, Congruency_History, Preparation_Time, Response_Direction, ...
    bsxfun(@times, Rule, Rule_Repetition), bsxfun(@times, Rule, Previous_Error), bsxfun(@times, Rule, Congruency_History), bsxfun(@times, Rule, Preparation_Time)];
level_names = [GLMCov(ismember({GLMCov.name}, 'Rule')).levels(rule_ind), ...
    strcat('Orientation:', GLMCov(ismember({GLMCov.name}, 'Rule Repetition')).levels(rule_rep_ind)), ...
    strcat('Orientation:', GLMCov(ismember({GLMCov.name}, 'Previous Error')).levels(prev_error_ind)), ...
    strcat('Orientation:', GLMCov(ismember({GLMCov.name}, 'Congruency History')).levels(con_hist_ind)), ...
    strcat('Orientation:', GLMCov(ismember({GLMCov.name}, 'Indicator Prep Time')).levels(prep_ind)), ...
    GLMCov(ismember({GLMCov.name}, 'Response Direction')).levels(response_ind), ...
    strcat('Color:', GLMCov(ismember({GLMCov.name}, 'Rule Repetition')).levels(rule_rep_ind)), ...
    strcat('Color:', GLMCov(ismember({GLMCov.name}, 'Previous Error')).levels(prev_error_ind)), ...
    strcat('Color:', GLMCov(ismember({GLMCov.name}, 'Congruency History')).levels(con_hist_ind)), ...
    strcat('Color:', GLMCov(ismember({GLMCov.name}, 'Indicator Prep Time')).levels(prep_ind))];

%% Reaction Time
Reaction_Time = cat(1, behavior.Reaction_Time);
% Fit Model
react_coef_CC = glmfit(designMatrix(isCC, :), Reaction_Time(isCC, :), 'normal', 'link', 'log');
react_coef_CH = glmfit(designMatrix(isCH, :), Reaction_Time(isCH, :), 'normal', 'link', 'log');
react_coef_ISA = glmfit(designMatrix(isISA, :), Reaction_Time(isISA, :), 'normal', 'link', 'log');

isColorRule = regexp(level_names, 'Color:');
isColorRule = find(cellfun(@(x) ~isempty(x), isColorRule)) + 1;
isOrientRule = regexp(level_names, 'Orientation:');
isOrientRule = find(cellfun(@(x) ~isempty(x), isOrientRule)) + 1;

isColorMainEffect = 2;

figure;
% Orientation Rule
subplot(2,1,1);
plot(100*(exp(react_coef_CC(isOrientRule(end:-1:1))) - 1), 1:length(isOrientRule), '--o'); hold all;
plot(100*(exp(react_coef_ISA(isOrientRule(end:-1:1))) - 1), 1:length(isOrientRule), '--o');
plot(100*(exp(react_coef_CH(isOrientRule(end:-1:1))) - 1), 1:length(isOrientRule), '--o');
vline(0, 'k');
set(gca, 'YTick', 1:length(isOrientRule))
set(gca, 'YTickLabel', level_names(isOrientRule(end:-1:1)-1))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Reaction Time');
xlim([-60 60]);
box off;
text(3,0,'Increase in Reaction Time (%) \rightarrow')
text(-3,0,'\leftarrow Decrease in Reaction Time (%)', 'HorizontalAlignment','right')
% Color Rule
subplot(2,1,2);
plot(100*(exp(react_coef_CC(isColorMainEffect) + react_coef_CC(isColorRule(end:-1:1))) - 1), 1:length(isColorRule), '--o'); hold all;
plot(100*(exp(react_coef_ISA(isColorMainEffect) + react_coef_ISA(isColorRule(end:-1:1))) - 1), 1:length(isColorRule), '--o');
plot(100*(exp(react_coef_CH(isColorMainEffect) + react_coef_CH(isColorRule(end:-1:1))) - 1), 1:length(isColorRule), '--o');
vline(0, 'k');
set(gca, 'YTick', 1:length(isColorRule))
set(gca, 'YTickLabel', level_names(isColorRule(end:-1:1)-1))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Reaction Time');
xlim([-60 60]);
box off;
text(3,0,'Increase in Reaction Time (%) \rightarrow')
text(-3,0,'\leftarrow Decrease in Reaction Time (%)', 'HorizontalAlignment','right')

%% Incorrect/Correct
Correct = double(cat(1, behavior.correct));

% Fit Model
correct_coef_CC = glmfit(designMatrix(isCC, :), Correct(isCC, :),'binomial','link','logit');
correct_coef_CH = glmfit(designMatrix(isCH, :), Correct(isCH, :),'binomial','link','logit');
correct_coef_ISA = glmfit(designMatrix(isISA, :), Correct(isISA, :),'binomial','link','logit');

figure;
% Orientation Rule
subplot(2,1,1);
plot(100*(exp(correct_coef_CC(isOrientRule(end:-1:1))) - 1), 1:length(isOrientRule), '--o'); hold all;
plot(100*(exp(correct_coef_ISA(isOrientRule(end:-1:1))) - 1), 1:length(isOrientRule), '--o');
plot(100*(exp(correct_coef_CH(isOrientRule(end:-1:1))) - 1), 1:length(isOrientRule), '--o');
vline(0, 'k');
set(gca, 'YTick', 1:length(isOrientRule))
set(gca, 'YTickLabel', level_names(isOrientRule(end:-1:1)-1))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Odds of Correct Response');
xlim([-500 500]);
box off;
text(3,0,'Increase in Odds of Correct Response \rightarrow')
text(-3,0,'\leftarrow Decrease in Odds of Correct Response', 'HorizontalAlignment','right')
% Color Rule
subplot(2,1,2);
plot(100*(exp(correct_coef_CC(isColorMainEffect) + correct_coef_CC(isColorRule(end:-1:1))) - 1), 1:length(isColorRule), '--o'); hold all;
plot(100*(exp(correct_coef_ISA(isColorMainEffect) + correct_coef_ISA(isColorRule(end:-1:1))) - 1), 1:length(isColorRule), '--o');
plot(100*(exp(correct_coef_CH(isColorMainEffect) + correct_coef_CH(isColorRule(end:-1:1))) - 1), 1:length(isColorRule), '--o');
vline(0, 'k');
set(gca, 'YTick', 1:length(isColorRule))
set(gca, 'YTickLabel', level_names(isColorRule(end:-1:1)-1))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Odds of Correct Response');
xlim([-500 500]);
box off;
text(3,0,'Increase in Odds of Correct Response \rightarrow')
text(-3,0,'\leftarrow Decrease in Odds of Correct Response', 'HorizontalAlignment','right')

%% Alternatively, Ratio of ratios - Reaction Time
figure;

plot(100*(exp(react_coef_CC(isColorRule(end:-1:1))) - 1), 1:length(isColorRule), '--o'); hold all;
plot(100*(exp(react_coef_ISA(isColorRule(end:-1:1))) - 1), 1:length(isColorRule), '--o');
plot(100*(exp(react_coef_CH(isColorRule(end:-1:1))) - 1), 1:length(isColorRule), '--o');
vline(0, 'k');
set(gca, 'YTick', 1:length(isColorRule))
set(gca, 'YTickLabel', level_names(isColorRule(end:-1:1)-1))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Reaction Time');
xlim([-60 60]);
box off;
text(3,0,'Increase in Reaction Time for Color Rule(%) \rightarrow')
text(-3,0,'\leftarrow Decrease in Reaction Time for Color Rule(%)', 'HorizontalAlignment','right')

%% Alternatively, Odds Ratio of Odds Ratios - Incorrect/Correct

figure;
plot(100*(exp(correct_coef_CC(isColorRule(end:-1:1))) - 1), 1:length(isColorRule), '--o'); hold all;
plot(100*(exp(correct_coef_ISA(isColorRule(end:-1:1))) - 1), 1:length(isColorRule), '--o');
plot(100*(exp(correct_coef_CH(isColorRule(end:-1:1))) - 1), 1:length(isColorRule), '--o');
vline(0, 'k');
set(gca, 'YTick', 1:length(isColorRule))
set(gca, 'YTickLabel', level_names(isColorRule(end:-1:1)-1))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Odds of Correct Response');
xlim([-500 500]);
box off;
text(3,0,'Increase in Odds of Correct Response \rightarrow')
text(-3,0,'\leftarrow Decrease in Odds of Correct Response', 'HorizontalAlignment','right')
