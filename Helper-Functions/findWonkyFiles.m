function [isBad, neuronNames] = findWonkyFiles(sessionName)
% Load Common Parameters
workingDir = getWorkingDir();
sessionFile = sprintf('%s/Processed Data/Entire Trial/SpikeCov/%s_SpikeCov.mat', workingDir, sessionName);
behaviorFile = sprintf('%s/Behavior/behavior.mat', workingDir);
paramSetFile = sprintf('%s/paramSet.mat', workingDir);
load(sessionFile, 'spikes', 'trialID', 'spikeCov', 'numNeurons',...
    'wire_number', 'unit_number');

meanByTrial = grpstats(spikes, trialID);
z = zscore(meanByTrial, [], 1);

extremeZ = abs(z) > 3;
consecNum = 4;

c = nan(size(extremeZ));
neuronNames = cell(numNeurons, 1);

for neuron_ind = 1:numNeurons,
    c(:, neuron_ind) = conv(double(extremeZ(:, neuron_ind)), ones(5,1), 'same');
    neuronNames{neuron_ind} = sprintf('%s_%d_%d', sessionName, wire_number(neuron_ind), unit_number(neuron_ind));
end

isBad = any(c == consecNum, 1);

end