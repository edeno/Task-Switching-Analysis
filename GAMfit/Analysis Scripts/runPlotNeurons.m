clear all; close all;
model = 's(Rule, Trial Time, knotDiff=50) + s(Previous Error, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50)';
%% dlPFC - Rule
covOfInterest = 'Rule Cues';
timePeriod = 'Rule Stimulus';
neuronName = {'isa23-4-1', 'cc7-4-2', 'isa23-7-1', 'cc5-3-2', 'isa12-4-1'};
for neuron_ind = 1:length(neuronName),
   plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);  
end

%% ACC - Rule
covOfInterest = 'Rule Cues';
timePeriod = 'Rule Stimulus';
neuronName = {'cc8-11-1', 'cc8-14-2', 'isa10-11-2', 'isa23-12-1', 'isa19-15-2', 'isa14-10-1', 'isa12-4-2'};
for neuron_ind = 1:length(neuronName),
   plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);  
end

%% dlPFC - Rule Repetition
covOfInterest = 'Rule Repetition';
timePeriod = 'Rule Stimulus';
neuronName = {'isa17-1-2', 'cc8-4-1', 'cc7-4-3', 'isa12-4-1', 'isa21-6-3', 'isa18-1-2'};
for neuron_ind = 1:length(neuronName),
   plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);  
end
%% dlPFC - Rule Repetition
covOfInterest = 'Rule Repetition';
timePeriod = 'Rule Stimulus';
neuronName = {''};
for neuron_ind = 1:length(neuronName),
   plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);  
end
