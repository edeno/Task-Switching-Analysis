clear variables;
workingDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', workingDir), 'neuronInfo');
neuronNames = [neuronInfo.values];
neuronNames = [neuronNames{:}];
neuronNames = {neuronNames.name};
neuronNames = cellfun(@(x) strrep(x, '-', '_'), neuronNames, 'UniformOutput', false);
timePeriod = 'Rule Response';
model = 's(Rule, Trial Time, knotDiff=50) + s(Previous Error History, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50)';

covOfInterest = {'Previous Error History', 'Rule Repetition', 'Congruency'};
timeToSig = cell(length(neuronNames), length(covOfInterest));

for cov_ind = 1:length(covOfInterest),
    parfor neuron_ind = 1:length(neuronNames),
        [timeToSig{neuron_ind, cov_ind}] = getSigTime(neuronNames{neuron_ind}, covOfInterest{cov_ind}, timePeriod, model);
    end
end