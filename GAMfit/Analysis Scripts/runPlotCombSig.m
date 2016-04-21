timePeriod = 'Rule Stimulus';
modelName = 'Rule + Previous Error History + Rule Repetition';
plotCombSig(modelName, timePeriod, 'brainArea', 'dlPFC')
plotCombSig(modelName, timePeriod, 'brainArea', 'ACC')
%%
timePeriod = 'Stimulus Response';
modelName = 'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction';
plotCombSig(modelName, timePeriod, 'brainArea', 'dlPFC')
plotCombSig(modelName, timePeriod, 'brainArea', 'ACC')
