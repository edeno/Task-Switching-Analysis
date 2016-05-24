timePeriod = 'Rule Stimulus';
modelName = 'Rule + Previous Error History + Rule Repetition';
plotCombSig(modelName, timePeriod, 'brainArea', 'dlPFC', 'maxComparisons', 3)
plotCombSig(modelName, timePeriod, 'brainArea', 'ACC', 'maxComparisons', 3)
%%
timePeriod = 'Stimulus Response';
modelName = 'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction';
plotCombSig(modelName, timePeriod, 'brainArea', 'dlPFC', 'maxComparisons', 3)
plotCombSig(modelName, timePeriod, 'brainArea', 'ACC', 'maxComparisons', 3)
