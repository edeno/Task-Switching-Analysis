onlySigNeurons = true;

model = 'Rule + Previous Error History + Rule Repetition';
timePeriod = 'Rule Stimulus';
plotCorrelateNeuronsToBehavior(model, timePeriod, 'onlySig', onlySigNeurons)
plotCorrelateNeuronsToBehavior(model, timePeriod, 'subject', 'cc', 'onlySig', onlySigNeurons)
plotCorrelateNeuronsToBehavior(model, timePeriod, 'subject', 'isa', 'onlySig',onlySigNeurons)
%%
model = 'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction';
timePeriod = 'Stimulus Response';
plotCorrelateNeuronsToBehavior(model, timePeriod, 'onlySig', onlySigNeurons)
plotCorrelateNeuronsToBehavior(model, timePeriod, 'subject', 'cc', 'onlySig',onlySigNeurons)
plotCorrelateNeuronsToBehavior(model, timePeriod, 'subject', 'isa', 'onlySig', onlySigNeurons)
