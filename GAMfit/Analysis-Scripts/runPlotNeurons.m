clear variables; close all;
workingDir = getWorkingDir();
set(0, 'defaultAxesFontName', 'Arial');
set(0, 'defaultTextFontName', 'Arial');
%% Rule Stimulus
model = 'Rule + Previous Error History + Rule Repetition';
timePeriod = 'Rule Stimulus';

% dlPFC - Rule
covOfInterest = 'Rule Cues';
neuronName = {'isa23-4-1', 'cc7-4-2', 'isa23-7-1', 'cc5-3-2', 'isa12-4-1'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end

% ACC - Rule
covOfInterest = 'Rule Cues';
neuronName = {'cc8-11-1', 'cc8-14-2', 'isa10-11-2', 'isa23-12-1', 'isa19-15-2', 'isa14-10-1'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end

% dlPFC - Rule Repetition
covOfInterest = 'Rule Repetition';
neuronName = {'isa17-1-2', 'cc8-4-1', 'cc7-4-3', 'isa12-4-1', 'isa21-6-3', 'isa18-1-2'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end

% ACC - Rule Repetition
covOfInterest = 'Rule Repetition';
neuronName = {'cc7-9-1', 'isa19-12-2', 'isa22-14-1', 'isa22-14-1', 'isa17-14-1'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end

% dlPFC - Previous Error History
covOfInterest = 'Previous Error History';
neuronName = {'isa22-8-1', 'isa9-6-2', 'cc8-7-2', 'isa12-5-1', 'isa1-3-1', 'isa18-2-1'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end

% ACC - Previous Error History
covOfInterest = 'Previous Error History';
neuronName = {'cc1-9-1', 'cc7-16-2', 'isa16-9-1', 'isa19-15-2', 'isa9-10-2', 'isa18-15-1', 'isa19-14-1', 'isa17-12-1'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end
%% Stimulus Response
model = 'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction';
timePeriod = 'Stimulus Response';

% dlPFC - Rule
covOfInterest = 'Rule Cues';
neuronName = {'isa23-4-1', 'cc7-4-2', 'isa23-7-1', 'cc5-3-2', 'isa12-4-1'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end

% ACC - Rule
covOfInterest = 'Rule Cues';
neuronName = {'cc8-11-1', 'cc8-14-2', 'isa10-11-2', 'isa23-12-1', 'isa19-15-2', 'isa14-10-1'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end

% dlPFC - Rule Repetition
covOfInterest = 'Rule Repetition';
neuronName = {'isa17-1-2', 'cc8-4-1', 'cc7-4-3', 'isa12-4-1', 'isa21-6-3', 'isa18-1-2'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end

% ACC - Rule Repetition
covOfInterest = 'Rule Repetition';
neuronName = {'cc7-9-1', 'isa19-12-2', 'isa22-14-1', 'isa22-14-1', 'isa17-14-1'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end

% dlPFC - Previous Error History
covOfInterest = 'Previous Error History';
neuronName = {'isa22-8-1', 'isa9-6-2', 'cc8-7-2', 'isa12-5-1', 'isa1-3-1', 'isa18-2-1'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end

% ACC - Previous Error History
covOfInterest = 'Previous Error History';
neuronName = {'cc1-9-1', 'cc7-16-2', 'isa16-9-1', 'isa19-15-2', 'isa9-10-2', 'isa18-15-1', 'isa19-14-1', 'isa17-12-1'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end

% dlPFC - Congruency
covOfInterest = 'Congruency';
neuronName = {'cc5-8-1', 'cc7-4-3', 'cc12-3-1', 'isa12-6-1', 'isa18-8-1'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end

% ACC - Congruency
covOfInterest = 'Congruency';
neuronName = {'cc5-10-1', 'cc1-9-2', 'isa24-16-2'};
for neuron_ind = 1:length(neuronName),
    plotSingleNeuronModel(neuronName{neuron_ind}, covOfInterest, timePeriod, model);
    export_fig(sprintf('%s/Figures/%s/%s', workingDir, timePeriod, get(gcf, 'Name')), '-eps', '-rgb', '-painters')
end
