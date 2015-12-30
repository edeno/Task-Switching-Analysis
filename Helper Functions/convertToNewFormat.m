% Converts gamfit and gampred files to new format
function convertToNewFormat(fileName)

load(fileName);
saveDir = pwd;

for curNeuron = 1:numNeurons,
    % Save name for each neuron
    neuronName = sprintf('%s_neuron_%s_%d_%d', neurons(curNeuron).brainArea, neurons(curNeuron).sessionName, neurons(curNeuron).wireNumber, neurons(curNeuron).unitNumber);
    if gamParams.isPrediction
        neuronSaveName = sprintf('%s/%s_GAMpred.mat', saveDir, neuronName);
    else
        neuronSaveName = sprintf('%s/%s_GAMfit.mat', saveDir, neuronName);
    end
    
    neuron = neurons(curNeuron);
    if ~isempty(stats)
        stat = stats(curNeuron);
    else
        stat = [];
    end
    
    save(neuronSaveName, 'neuron', 'stat', '-v7.3');
end

fprintf('\nSaving GAMs ...\n');
save(fileName, ...
    'gam', 'num*', 'gamParams', ...
    'designMatrix', 'spikeCov', '-v7.3');

end