clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
load([main_dir, '/paramSet.mat'], 'data_info');
load([data_info.behavior_dir, '/behavior.mat']);
load([data_info.processed_dir, '/Intertrial Interval/GLMCov/', 'cc1_GLMCov.mat'], 'GLMCov');

monkey = cat(1, behavior.monkey);
isCC = ismember(monkey, 'CC');
isCH = ismember(monkey, 'CH');
isISA = ismember(monkey, 'ISA');

% Covariates
Rule = dummyvar(cat(1, behavior.Rule));
Switch = dummyvar(cat(1, behavior.Switch));
Rule_Repetition = dummyvar(cat(1, behavior.Rule_Repetition));
Previous_Error = dummyvar(cat(1, behavior.Previous_Error_History));
Congruency_History = dummyvar(cat(1, behavior.Congruency_History));
Preparation_Time = dummyvar(cat(1, behavior.Indicator_Prep_Time));
Response_Direction = dummyvar(cat(1, behavior.Response_Direction));

% Drop level
notBaseline = @(cov) find(~ismember(GLMCov(ismember({GLMCov.name}, cov)).levels, GLMCov(ismember({GLMCov.name}, cov)).baselineLevel));
rule_ind = notBaseline('Rule');
Rule = Rule(:, rule_ind);
rule_rep_ind = notBaseline('Rule Repetition');
Rule_Repetition = Rule_Repetition(:, rule_rep_ind);
prev_error_ind =  notBaseline('Previous Error History');
Previous_Error = Previous_Error(:, prev_error_ind);
con_hist_ind = notBaseline('Congruency History');
Congruency_History = Congruency_History(:, con_hist_ind);
prep_ind = notBaseline('Indicator Prep Time');
Preparation_Time = Preparation_Time(:, prep_ind);
response_ind = notBaseline('Response Direction');
Response_Direction = Response_Direction(:, response_ind);

% Create Design Matrix
designMatrix = [Rule, Rule_Repetition, Previous_Error, Congruency_History, Preparation_Time, Response_Direction, ...
    bsxfun(@times, Rule, Rule_Repetition), bsxfun(@times, Rule, Previous_Error), bsxfun(@times, Rule, Congruency_History), bsxfun(@times, Rule, Preparation_Time)];
level_names = [GLMCov(ismember({GLMCov.name}, 'Rule')).levels(rule_ind), ...
    strcat('Orientation:', GLMCov(ismember({GLMCov.name}, 'Rule Repetition')).levels(rule_rep_ind)), ...
    strcat('Orientation:', GLMCov(ismember({GLMCov.name}, 'Previous Error History')).levels(prev_error_ind)), ...
    strcat('Orientation:', GLMCov(ismember({GLMCov.name}, 'Congruency History')).levels(con_hist_ind)), ...
    strcat('Orientation:', GLMCov(ismember({GLMCov.name}, 'Indicator Prep Time')).levels(prep_ind)), ...
    GLMCov(ismember({GLMCov.name}, 'Response Direction')).levels(response_ind), ...
    strcat('Color:', GLMCov(ismember({GLMCov.name}, 'Rule Repetition')).levels(rule_rep_ind)), ...
    strcat('Color:', GLMCov(ismember({GLMCov.name}, 'Previous Error History')).levels(prev_error_ind)), ...
    strcat('Color:', GLMCov(ismember({GLMCov.name}, 'Congruency History')).levels(con_hist_ind)), ...
    strcat('Color:', GLMCov(ismember({GLMCov.name}, 'Indicator Prep Time')).levels(prep_ind))];

isColorRule = regexp(level_names, 'Color:');
isColorRule = find(cellfun(@(x) ~isempty(x), isColorRule)) + 1;
isOrientRule = regexp(level_names, 'Orientation:');
isOrientRule = find(cellfun(@(x) ~isempty(x), isOrientRule)) + 1;

%% Reaction Time
Reaction_Time = cat(1, behavior.Reaction_Time);
% Fit Model
react_coef_CC = glmfit(designMatrix(isCC, :), Reaction_Time(isCC, :), 'normal', 'link', 'log');
react_coef_CH = glmfit(designMatrix(isCH, :), Reaction_Time(isCH, :), 'normal', 'link', 'log');
react_coef_ISA = glmfit(designMatrix(isISA, :), Reaction_Time(isISA, :), 'normal', 'link', 'log');

figure;

plot(react_coef_CC(isColorRule(end:-1:1)), 1:length(isColorRule), '--o'); hold all;
plot(react_coef_ISA(isColorRule(end:-1:1)), 1:length(isColorRule), '--o');
plot(react_coef_CH(isColorRule(end:-1:1)), 1:length(isColorRule), '--o');
vline(0, 'k');
ylim([1-.5, length(isColorRule)+.5]);
set(gca, 'YTick', 1:length(isColorRule))
set(gca, 'YTickLabel', level_names(isColorRule(end:-1:1)-1))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Reaction Time (Relative to the Orientation Rule)');
xlim(log([0.7, 1.4]))
set(gca, 'XTick', log(0.7:0.1:1.4))
set(gca, 'XTickLabel', -30:10:40)
box off;
text(0.05,0,'Increase in Reaction Time for Color Rule(%) \rightarrow')
text(-0.05,0,'\leftarrow Decrease in Reaction Time for Color Rule(%)', 'HorizontalAlignment','right')
grid on;
%% Incorrect/Correct
Correct = double(cat(1, behavior.correct));

% Fit Model
correct_coef_CC = glmfit(designMatrix(isCC, :), Correct(isCC, :),'binomial','link','logit');
correct_coef_CH = glmfit(designMatrix(isCH, :), Correct(isCH, :),'binomial','link','logit');
correct_coef_ISA = glmfit(designMatrix(isISA, :), Correct(isISA, :),'binomial','link','logit');

figure;
plot(correct_coef_CC(isColorRule(end:-1:1)), 1:length(isColorRule), '--o'); hold all;
plot(correct_coef_ISA(isColorRule(end:-1:1)), 1:length(isColorRule), '--o');
plot(correct_coef_CH(isColorRule(end:-1:1)), 1:length(isColorRule), '--o');
vline(0, 'k');
ylim([1-.5, length(isColorRule)+.5]);
set(gca, 'YTick', 1:length(isColorRule))
set(gca, 'YTickLabel', level_names(isColorRule(end:-1:1)-1))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Odds of Correct Response (Relative to the Orientation Rule)');
xlim(log([0.05, 9.5]))
set(gca, 'XTick', log([0.1:0.1:0.4, 0.5:0.5:2, 3:2:9]))
set(gca, 'XTickLabel', [-90:10:-60, -50:50:100,200:200:800])
box off;
text(0.05,0,'Increase in Odds of Correct Response \rightarrow')
text(-0.05,0,'\leftarrow Decrease in Odds of Correct Response', 'HorizontalAlignment','right')
grid on;