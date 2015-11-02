model = 'Rule + Rule Repetition + Normalized Preparation Time + Previous Error History + Congruency History + Response Direction';

ccColor = [102,194,165] / 255;
isaColor = [117,112,179] / 255;
correctTrialsOnly = false;

figure;
ccHandle = plotBehaviorReactMultiples(model, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', correctTrialsOnly);
isaHandle = plotBehaviorReactMultiples(model, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', correctTrialsOnly);
legendHandle = legend([ccHandle{1}, isaHandle{1}], {'Monkey CC', 'Monkey ISA'});
legendHandle.Box = 'off';
suptitle('Reaction Time');

figure;
ccHandle = reactModelCheck(model, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', correctTrialsOnly);
suptitle('Monkey CC');
figure;
isaHandle = reactModelCheck(model, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', correctTrialsOnly);
suptitle('Monkey ISA');

%%
model = 'Rule + Rule Repetition + Normalized Preparation Time + Previous Error History Indicator + Congruency History + Response Direction';

figure;
ccHandle = plotBehaviorReactMultiples(model, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', false);
isaHandle = plotBehaviorReactMultiples(model, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', false);
legendHandle = legend([ccHandle{1}, isaHandle{1}], {'Monkey CC', 'Monkey ISA'});
legendHandle.Box = 'off';
suptitle('Reaction Time');

figure;
subplot(2,1,1);
ccHandle = reactModelCheck(model, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', false);
subplot(2,1,2);
isaHandle = reactModelCheck(model, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', false);

%%
model = 'Rule * Rule Repetition + Rule * Normalized Preparation Time + Previous Error History + Congruency History + Response Direction';

% figure;
% ccHandle = plotBehaviorReactMultiples(model, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', false);
% isaHandle = plotBehaviorReactMultiples(model, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', false);
% legendHandle = legend([ccHandle{1}, isaHandle{1}], {'Monkey CC', 'Monkey ISA'});
% legendHandle.Box = 'off';
% suptitle('Reaction Time');

figure;
subplot(2,1,1);
ccHandle = reactModelCheck(model, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', false);
subplot(2,1,2);
isaHandle = reactModelCheck(model, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', false);

%%

model = 'Rule * Normalized Preparation Time + Response Direction + Rule * Rule Repetition + Congruency + Previous Error';

% figure;
% ccHandle = plotBehaviorReactMultiples(model, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', false);
% isaHandle = plotBehaviorReactMultiples(model, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', false);
% legendHandle = legend([ccHandle{1}, isaHandle{1}], {'Monkey CC', 'Monkey ISA'});
% legendHandle.Box = 'off';
% suptitle('Reaction Time');

figure;
ccHandle = reactModelCheck(model, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', false);
isaHandle = reactModelCheck(model, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', false);
suptitle(model);

%%
model = {'Rule', 'Normalized Preparation Time', 'Rule + Normalized Preparation Time', ...
    'Rule * Normalized Preparation Time', 'Rule * Normalized Preparation Time + Rule * Rule Repetition', ...
    'Rule * Normalized Preparation Time + Rule * Rule Repetition + Response Direction', ...
    'Rule * Normalized Preparation Time + Rule * Rule Repetition + Response Direction + Congruency', ...
    'Rule * Normalized Preparation Time + Rule * Rule Repetition + Response Direction + Congruency + Previous Error History', ...
    'Rule Cues * Normalized Preparation Time + Rule Cues * Rule Cue Switch + Response Direction + Congruency + Previous Error History', ...
    'Rule * Normalized Preparation Time + Rule * Rule Repetition + Response Direction * Normalized Preparation Time + Congruency + Previous Error History'};

for k = 1:length(model),
    figure;
    ccHandle = reactModelCheck(model{k}, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', false);

    isaHandle = reactModelCheck(model{k}, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', false);
    suptitle(model{k});
end