model = 'Previous Error History + Rule * Rule Repetition + Congruency + Normalized Preparation Time';
ccColor = [102,194,165] / 255;
isaColor = [117,112,179] / 255;
correctTrialsOnly = false;

figure;
plotBehaviorReactMultiples(model, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', true)
plotBehaviorReactMultiples(model, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', true)

%%
model = 'Rule * Previous Error History + Rule Repetition + Congruency + Normalized Preparation Time';
figure;
plotBehaviorCorrectMultiples(model, 'Monkey', 'CC', 'Color', ccColor, 'correctTrialsOnly', false)
plotBehaviorCorrectMultiples(model, 'Monkey', 'ISA', 'Color', isaColor, 'correctTrialsOnly', false)
