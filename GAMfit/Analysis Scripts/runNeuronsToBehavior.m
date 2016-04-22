onlySigNeurons = true;

model = 'Rule + Previous Error History + Rule Repetition';
timePeriod = 'Rule Stimulus';
plotNeuronsToBehavior(model, timePeriod, 'onlySig', onlySigNeurons)
plotNeuronsToBehavior(model, timePeriod, 'subject', 'cc', 'onlySig', onlySigNeurons)
plotNeuronsToBehavior(model, timePeriod, 'subject', 'isa', 'onlySig',onlySigNeurons)
%%
model = 'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction';
timePeriod = 'Stimulus Response';
plotNeuronsToBehavior(model, timePeriod, 'onlySig', onlySigNeurons)
plotNeuronsToBehavior(model, timePeriod, 'subject', 'cc', 'onlySig',onlySigNeurons)
plotNeuronsToBehavior(model, timePeriod, 'subject', 'isa', 'onlySig', onlySigNeurons)
