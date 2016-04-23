function [parEst, gam, neuronNames, neuronBrainAreas, p, h] = getSplineCoef(modelName, timePeriod, varargin)
inParser = inputParser;
inParser.addRequired('modelName', @ischar);
inParser.addRequired('timePeriod', @ischar);
inParser.addParameter('brainArea', '*', @ischar);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('sessionName', '*', @ischar);
inParser.addParameter('isConstraints', false, @islogical)
inParser.addParameter('isSim', false, @islogical)
inParser.addParameter('numSim', 1000, @(x) isnumeric(x) & all(x > 0));

inParser.parse(modelName, timePeriod, varargin{:});
params = inParser.Results;

workingDir = getWorkingDir();
modelsDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
load(sprintf('%s/modelList.mat', modelsDir));
load(sprintf('%s/paramSet.mat', workingDir), 'sessionNames');

if strcmp(params.sessionName, '*')
    neuronFiles = sprintf('%s/%s/%s_neuron_%s*_GAMfit.mat', modelsDir, modelList(modelName), params.brainArea, params.subject);
else
    neuronFiles = sprintf('%s/%s/%s_neuron_%s_*_GAMfit.mat', modelsDir, modelList(modelName), params.brainArea, params.sessionName);
end

neuronFiles = dir(neuronFiles);
neuronFiles = {neuronFiles.name};

nameSplit = cellfun(@(x) strsplit(x, '_'), neuronFiles, 'UniformOutput', false);
neuronNames = cellfun(@(x) strjoin(x(:, 3:5), '-'), nameSplit, 'UniformOutput', false);
neuronBrainAreas = cellfun(@(x) x{:, 1}, nameSplit, 'UniformOutput', false);

gam = cell(length(sessionNames), 1);
for session_ind = 1:length(sessionNames),
    fprintf('\nLoading... %s\n', sessionNames{session_ind});
    file = load(sprintf('%s/%s/%s_GAMfit.mat', modelsDir, modelList(modelName), sessionNames{session_ind}), 'gam');
    file.gam = rmfield(file.gam, {'penalty', 'sqrtPen', 'trialID','trialTime'});
    file.gam.bsplines = cellfun(@(x) rmfield(x, {'time', 'basis', 'sqrtPen', 'penalty', 'con_basis', 'con_sqrtPen', 'knotsDiff', 'rank'}), file.gam.bsplines);
    gam{session_ind} =  file.gam;
end

gam = [gam{:}];
if params.isConstraints,
    maxParams = arrayfun(@(x) length(x.constraintLevel_names), gam, 'UniformOutput', false);
    [numParams, max_ind] = max([maxParams{:}]);
    levelNames = gam(max_ind).constraintLevel_names;
else
    maxParams = arrayfun(@(x) length(x.levelNames), gam, 'UniformOutput', false);
    [numParams, max_ind] = max([maxParams{:}]);
    levelNames = gam(max_ind).levelNames;
end


if params.isSim,
    parEst = nan(length(neuronFiles), numParams, params.numSim);
else
    parEst = nan(length(neuronFiles), numParams);
end
p = nan(length(neuronFiles), numParams);

for file_ind = 1:length(neuronFiles),
    fprintf('\nLoading... %s\n', neuronFiles{file_ind});
    file = load(sprintf('%s/%s/%s', modelsDir, modelList(modelName), neuronFiles{file_ind}));
    sessionID = ismember(sessionNames, file.neuron.sessionName);
    if params.isConstraints,
        levelID = ismember(levelNames, gam(sessionID).constraintLevel_names);
        if params.isSim,
            parEst(file_ind, levelID, :) =  mvnrnd(file.neuron.parEst, file.stat.covb, params.numSim)';
        else
            parEst(file_ind, levelID) =  file.neuron.parEst';
        end
    else
        levelID = ismember(levelNames, gam(sessionID).levelNames);
        if params.isSim,
            parEst(file_ind, levelID, :) =  gam(sessionID).constraints * mvnrnd(file.neuron.parEst, file.stat.covb, params.numSim);
        else
            parEst(file_ind, levelID) =  gam(sessionID).constraints' * file.neuron.parEst;
        end
    end
    
    p(file_ind, levelID) = file.stat.p;
end

alpha = 0.05;
sortedP = sort(p(:));
numP = length(p(:));

thresholdLine = ([1:numP]' / numP) * alpha;
threshold_ind = find(sortedP <= thresholdLine, 1, 'last');
threshold = sortedP(threshold_ind);

h = p < threshold;
end