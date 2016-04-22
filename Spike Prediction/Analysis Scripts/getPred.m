function [pred, gam, neuronNames, neuronBrainAreas] = getPred(modelName, timePeriod, varargin)

inParser = inputParser;
inParser.addRequired('modelName', @ischar);
inParser.addRequired('timePeriod', @ischar);
inParser.addParameter('brainArea', '*', @ischar);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('predType', 'AUC', @ischar);

inParser.parse(modelName, timePeriod, varargin{:});
params = inParser.Results;

workingDir = getWorkingDir();
modelsDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
load(sprintf('%s/modelList.mat', modelsDir));

neuronFiles = sprintf('%s/%s/%s_neuron_%s*_GAMpred.mat', modelsDir, modelList(modelName), params.brainArea, params.subject);

neuronFiles = dir(neuronFiles);
neuronFiles = {neuronFiles.name};

load(sprintf('%s/%s/cc1_GAMpred.mat', modelsDir, modelList(modelName)), 'gam', 'gamParams');

nameSplit = cellfun(@(x) strsplit(x, '_'), neuronFiles, 'UniformOutput', false);
neuronNames = cellfun(@(x) strjoin(x(:, 3:5), '-'), nameSplit, 'UniformOutput', false);
neuronBrainAreas = cellfun(@(x) x{:, 1}, nameSplit, 'UniformOutput', false);
pred = nan(length(neuronFiles), gamParams.numFolds);

for file_ind = 1:length(neuronFiles),
    fprintf('\nLoading... %s\n', neuronFiles{file_ind});
    file = load(sprintf('%s/%s/%s', modelsDir, modelList(modelName), neuronFiles{file_ind}));
    pred(file_ind, :) = file.neuron.(params.predType);
end

end