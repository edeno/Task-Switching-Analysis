function [parEst, gam, neuronNames, neuronBrainAreas, p, h] = getCoef(modelName, timePeriod, varargin)

inParser = inputParser;
inParser.addRequired('modelName', @ischar);
inParser.addRequired('timePeriod', @ischar);
inParser.addParameter('brainArea', '*', @ischar);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('isSim', false, @islogical)
inParser.addParameter('numSim', 1000, @(x) isnumeric(x) & all(x > 0));

inParser.parse(modelName, timePeriod, varargin{:});
params = inParser.Results;

workingDir = getWorkingDir();
modelsDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
load(sprintf('%s/modelList.mat', modelsDir));

neuronFiles = sprintf('%s/%s/%s_neuron_%s*_GAMfit.mat', modelsDir, modelList(modelName), params.brainArea, params.subject);

neuronFiles = dir(neuronFiles);
neuronFiles = {neuronFiles.name};

load(sprintf('%s/%s/cc1_GAMfit.mat', modelsDir, modelList(modelName)), 'gam');

nameSplit = cellfun(@(x) strsplit(x, '_'), neuronFiles, 'UniformOutput', false);
neuronNames = cellfun(@(x) strjoin(x(:, 3:5), '-'), nameSplit, 'UniformOutput', false);
neuronBrainAreas = cellfun(@(x) x{:, 1}, nameSplit, 'UniformOutput', false);

if params.isSim,
    parEst = nan(length(neuronFiles), length(gam.levelNames), params.numSim);
else
    parEst = nan(length(neuronFiles), length(gam.levelNames));
end
p = nan(length(neuronFiles), length(gam.levelNames));

for file_ind = 1:length(neuronFiles),
    fprintf('\nLoading... %s\n', neuronFiles{file_ind});
    file = load(sprintf('%s/%s/%s', modelsDir, modelList(modelName), neuronFiles{file_ind}));
    if params.isSim,
        parEst(file_ind, :, :) =  mvnrnd(file.neuron.parEst, file.stat.covb, params.numSim)';
    else
        parEst(file_ind, :) =  file.neuron.parEst';
    end
    p(file_ind, :) = file.stat.p;
end

alpha = 0.05;
sortedP = sort(p(:));
numP = length(p(:));

thresholdLine = ([1:numP]' / numP) * alpha;
threshold_ind = find(sortedP <= thresholdLine, 1, 'last');
threshold = sortedP(threshold_ind);

h = p < threshold;

end