clear variables; clc;
main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), 'covInfo');
load(sprintf('%s/Behavior/behavior.mat', main_dir));

behavior = mergeMap(behavior);

isCC = ismember(behavior('Monkey'), 'CC');
isISA = ismember(behavior('Monkey'), 'ISA');

%% Create Design Matrix
model = 'Rule + Rule Repetition + Preparation Time Indicator + Previous Error History + Congruency History + Response Direction';
[designMatrix, gam] = gamModelMatrix(model, behavior, covInfo, 'level_reference', 'Reference');
%% Reaction Time
reactionTime = behavior('Reaction Time');

% Fit Model
[react_coef_CC, react_dev_CC, react_stats_CC] = glmfit(designMatrix(isCC, :), reactionTime(isCC, :), 'normal', 'link', 'log', 'constant', 'off');
[react_coef_ISA, react_dev_ISA, react_stats_ISA] =  glmfit(designMatrix(isISA, :), reactionTime(isISA, :), 'normal', 'link', 'log', 'constant', 'off');

% Standard Errors
react_se_CC = [react_stats_CC.beta - react_stats_CC.se, react_stats_CC.beta + react_stats_CC.se];
react_se_ISA = [react_stats_ISA.beta - react_stats_ISA.se, react_stats_ISA.beta + react_stats_ISA.se];

% log scale
figure;
subplot(3, 2, 1:4);
plot(react_coef_CC(end:-1:2), 1:length(gam.levelNames) - 1, '.-', 'color', 'b'); hold all;
plot(react_coef_ISA(end:-1:2), 1:length(gam.levelNames) - 1, '.-', 'color', [0.00  0.50  0.00]);
vline(0, 'k');
plot(react_se_CC(end:-1:2,  :)', [1:length(gam.levelNames) - 1; 1:length(gam.levelNames) - 1], 'b')
plot(react_se_ISA(end:-1:2,  :)', [1:length(gam.levelNames) - 1; 1:length(gam.levelNames) - 1], 'color', [0.00  0.50  0.00])
set(gca, 'YTick', 1:length(gam.levelNames) - 1)
set(gca, 'YTickLabel', gam.levelNames(end:-1:2))
set(gca, 'YTick', 1:length(gam.levelNames) - 1)
set(gca, 'YTickLabel', gam.levelNames(end:-1:2))
set(gca, 'XAxisLocation', 'top')
xlim(log([0.85, 1.15]))
ylim([1-.5, length(gam.levelNames)-1+.5]);
set(gca, 'XTick', log(0.85:0.05:1.15))
set(gca, 'XTickLabel', -10:5:10)
legend({'CC', 'ISA'});
title('Percent Change in Reaction Time');

box off;
text(0.05,0,'Slower Reaction Time (%) \rightarrow')
text(-0.05,0,'\leftarrow Faster Reaction Time (%)', 'HorizontalAlignment','right')
grid on;

edges = [0:10:1400];
subplot(3, 2, 5:6);
h = histogram(reactionTime(isCC, :));
h.DisplayStyle = 'stairs';
h.Normalization = 'probability';
h.EdgeColor = 'blue';
vline(exp(react_coef_CC(1)), 'b');
ylabel('Probability');
hold all;
h = histogram(reactionTime(isISA, :), 'Normalization', 'probability');
h.DisplayStyle = 'stairs';
h.Normalization = 'probability';
h.EdgeColor = 'green';
vline(exp(react_coef_ISA(1)), 'g');
xlabel('Reaction Time (ms)');

%% Incorrect/Correct
Correct = behavior('Correct');

% Fit Model
[correct_coef_CC, correct_dev_CC, correct_stats_CC] = glmfit(designMatrix(isCC, :), Correct(isCC, :),'binomial','link','logit', 'constant', 'off');
[correct_coef_ISA, correct_dev_ISA, correct_stats_ISA] = glmfit(designMatrix(isISA, :), Correct(isISA, :),'binomial','link','logit', 'constant', 'off');

% Standard Errors
correct_se_CC = [correct_stats_CC.beta - correct_stats_CC.se, correct_stats_CC.beta + correct_stats_CC.se];
correct_se_ISA = [correct_stats_ISA.beta - correct_stats_ISA.se, correct_stats_ISA.beta + correct_stats_ISA.se];

% log scale
figure;
plot(correct_coef_CC(end:-1:2), 1:length(gam.levelNames) - 1, '.-', 'color', 'b'); hold all;
plot(correct_coef_ISA(end:-1:2), 1:length(gam.levelNames) - 1, '.-', 'color', 'g');
vline(0, 'k');
plot(correct_se_CC(end:-1:2,  :)', [1:length(gam.levelNames) - 1; 1:length(gam.levelNames) - 1], 'b')
plot(correct_se_ISA(end:-1:2,  :)', [1:length(gam.levelNames) - 1; 1:length(gam.levelNames) - 1], 'g')
set(gca, 'YTick', 1:length(gam.levelNames) - 1)
set(gca, 'YTickLabel', gam.levelNames(end:-1:2))
set(gca, 'XAxisLocation', 'top')
legend({'CC', 'ISA'});
title('Percent Change in Odds of Correct Response');
xlim(log([0.05, 9.5]))
set(gca, 'XTick', log([0.1:0.1:0.4, 0.5:0.5:2, 3:2:9]))
set(gca, 'XTickLabel', [-90:10:-60, -50:50:100,200:200:800])
box off;
ylim([1-.5, length(gam.levelNames)-1+.5]);
text(0.05,0,'Increase in Odds of Correct Response \rightarrow')
text(-0.05,0,'\leftarrow Decrease in Odds of Correct Response', 'HorizontalAlignment','right')
grid on;
