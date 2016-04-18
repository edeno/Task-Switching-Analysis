model = 'Previous Error History + Rule * Rule Repetition + Congruency + Session Time + Normalized Preparation Time';
ccColor = [102,194,165] / 255;
isaColor = [117,112,179] / 255;

figure;
[~, ~, ~, statsReact_CC, ~] = plotBehaviorReactMultiples(model, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', false);
[~, ~, ~, statsReact_ISA, gamReact] = plotBehaviorReactMultiples(model, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', false);

%%
model = 'Rule + Previous Error History + Rule Repetition + Congruency + Session Time';
figure;
[~, ~, ~, statsCorrect_CC, ~] = plotBehaviorCorrectMultiples(model, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', false);
[~, ~, ~, statsCorrect_ISA, gamCorrect] = plotBehaviorCorrectMultiples(model, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', false);
