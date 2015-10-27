model = 'Rule + Rule Repetition + Preparation Time Indicator + Previous Error History Indicator + Congruency History';
figure;
ccColor = [102,194,165] / 255;
isaColor = [117,112,179] / 255;
ccHandle = plotBehaviorReactMultiples(model, 'Monkey', 'CC', 'Color', ccColor);
isaHandle = plotBehaviorReactMultiples(model, 'Monkey', 'ISA', 'Color', isaColor);
legendHandle = legend([ccHandle{1}, isaHandle{1}], {'CC', 'ISA'});
legendHandle.Box = 'off';