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
switch_ind = notBaseline('Switch');
Switch = Switch(:, switch_ind);
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
designMatrix = [Rule, Rule_Repetition, Previous_Error, Congruency_History, Preparation_Time, Response_Direction];
level_names = [GLMCov(ismember({GLMCov.name}, 'Rule')).levels(rule_ind), ...
    GLMCov(ismember({GLMCov.name}, 'Rule Repetition')).levels(rule_rep_ind), ...
    GLMCov(ismember({GLMCov.name}, 'Previous Error History')).levels(prev_error_ind), ...
    GLMCov(ismember({GLMCov.name}, 'Congruency History')).levels(con_hist_ind), ...
    GLMCov(ismember({GLMCov.name}, 'Indicator Prep Time')).levels(prep_ind), ...
    GLMCov(ismember({GLMCov.name}, 'Response Direction')).levels(response_ind)];

%% Reaction Time
Reaction_Time = cat(1, behavior.Reaction_Time);

% Fit Model
[react_coef_CC, react_dev_CC, react_stats_CC] = glmfit(designMatrix(isCC, :), Reaction_Time(isCC, :), 'normal', 'link', 'log');
[react_coef_ISA, react_dev_ISA, react_stats_ISA] =  glmfit(designMatrix(isISA, :), Reaction_Time(isISA, :), 'normal', 'link', 'log');
[react_coef_CH, react_dev_CH, react_stats_CH] = glmfit(designMatrix(isCH, :), Reaction_Time(isCH, :), 'normal', 'link', 'log');

% Standard Errors
react_se_CC = [react_stats_CC.beta - react_stats_CC.se, react_stats_CC.beta + react_stats_CC.se];
react_se_ISA = [react_stats_ISA.beta - react_stats_ISA.se, react_stats_ISA.beta + react_stats_ISA.se];
react_se_CH = [react_stats_CH.beta - react_stats_CH.se, react_stats_CH.beta + react_stats_CH.se];

% log scale
figure;
subplot(3, 3, 1:6);
plot(react_coef_CC(end:-1:2), 1:length(level_names), '-'); hold all;
plot(react_coef_ISA(end:-1:2), 1:length(level_names), '-');
plot(react_coef_CH(end:-1:2), 1:length(level_names), '-');
vline(0, 'k');
plot(react_se_CC(end:-1:2,  :)', [1:length(level_names); 1:length(level_names)], 'b')
plot(react_se_ISA(end:-1:2,  :)', [1:length(level_names); 1:length(level_names)], 'g')
plot(react_se_CH(end:-1:2,  :)', [1:length(level_names); 1:length(level_names)], 'r')
set(gca, 'YTick', 1:length(level_names))
set(gca, 'YTickLabel', level_names(end:-1:1))
set(gca, 'YTick', 1:length(level_names))
set(gca, 'YTickLabel', level_names(end:-1:1))
set(gca, 'XAxisLocation', 'top')
xlim(log([0.7, 1.4]))
ylim([1-.5, length(level_names)+.5]);
set(gca, 'XTick', log(0.7:0.1:1.4))
set(gca, 'XTickLabel', -30:10:40)
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Reaction Time');

box off;
text(0.05,0,'Increase in Reaction Time (%) \rightarrow')
text(-0.05,0,'\leftarrow Decrease in Reaction Time (%)', 'HorizontalAlignment','right')
grid on;

edges = [0:10:1400];
subplot(3, 3, 7);
n = histc(Reaction_Time(isCC, :), edges);
bar(edges,n/sum(n),'histc')
vline(exp(react_coef_CC(1)));
title('CC')
xlabel('Reaction Time (ms)');
ylabel('Relative Frequency');
subplot(3, 3, 8);
n = histc(Reaction_Time(isISA, :), edges);
bar(edges,n/sum(n),'histc')
vline(exp(react_coef_ISA(1)));
title('ISA')
xlabel('Reaction Time (ms)');

subplot(3, 3, 9);
n = histc(Reaction_Time(isCH, :), edges);
bar(edges,n/sum(n),'histc')
vline(exp(react_coef_CH(1)));
title('CH')
xlabel('Reaction Time (ms)');

%% Incorrect/Correct
Correct = double(cat(1, behavior.correct));

% Fit Model
[correct_coef_CC, correct_dev_CC, correct_stats_CC] = glmfit(designMatrix(isCC, :), Correct(isCC, :),'binomial','link','logit');
[correct_coef_ISA, correct_dev_ISA, correct_stats_ISA] = glmfit(designMatrix(isISA, :), Correct(isISA, :),'binomial','link','logit');
[correct_coef_CH, correct_dev_CH, correct_stats_CH] = glmfit(designMatrix(isCH, :), Correct(isCH, :),'binomial','link','logit');

% Standard Errors
correct_se_CC = [correct_stats_CC.beta - correct_stats_CC.se, correct_stats_CC.beta + correct_stats_CC.se];
correct_se_ISA = [correct_stats_ISA.beta - correct_stats_ISA.se, correct_stats_ISA.beta + correct_stats_ISA.se];
correct_se_CH = [correct_stats_CH.beta - correct_stats_CH.se, correct_stats_CH.beta + correct_stats_CH.se];

% log scale
figure;
plot(correct_coef_CC(end:-1:2), 1:length(level_names), '-'); hold all;
plot(correct_coef_ISA(end:-1:2), 1:length(level_names), '-');
plot(correct_coef_CH(end:-1:2), 1:length(level_names), '-');
vline(0, 'k');
plot(correct_se_CC(end:-1:2,  :)', [1:length(level_names); 1:length(level_names)], 'b')
plot(correct_se_ISA(end:-1:2,  :)', [1:length(level_names); 1:length(level_names)], 'g')
plot(correct_se_CH(end:-1:2,  :)', [1:length(level_names); 1:length(level_names)], 'r')
set(gca, 'YTick', 1:length(level_names))
set(gca, 'YTickLabel', level_names(end:-1:1))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA', 'CH'});
title('Percent Change in Odds of Correct Response');
xlim(log([0.05, 9.5]))
set(gca, 'XTick', log([0.1:0.1:0.4, 0.5:0.5:2, 3:2:9]))
set(gca, 'XTickLabel', [-90:10:-60, -50:50:100,200:200:800])
box off;
ylim([1-.5, length(level_names)+.5]);
text(0.05,0,'Increase in Odds of Correct Response \rightarrow')
text(-0.05,0,'\leftarrow Decrease in Odds of Correct Response', 'HorizontalAlignment','right')
grid on;
