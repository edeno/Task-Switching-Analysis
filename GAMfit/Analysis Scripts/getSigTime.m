function [timeToSig, levelsOfInterest] = getSigTime(neuronName, covOfInterest, timePeriod, model, varargin)
numSim = 1000;
workingDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', workingDir), 'covInfo');

sessionName = strsplit(neuronName, '_');
sessionName = sessionName{1};
modelDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
load(sprintf('%s/modelList.mat', modelDir), 'modelList');

load(sprintf('%s/%s/%s_GAMfit.mat', modelDir, modelList(model), sessionName), 'gam');
neuronFile = dir(sprintf('%s/%s/*_neuron_%s_GAMfit.mat', modelDir, modelList(model), neuronName));
load(sprintf('%s/%s/%s', modelDir, modelList(model), neuronFile.name));

levelNames = [gam.levelNames];

levelsOfInterest = covInfo(covOfInterest).levels;
levelsOfInterest = levelsOfInterest(~ismember(levelsOfInterest, covInfo(covOfInterest).baselineLevel));
numLevels = length(levelsOfInterest);

getTimeLevels = @(level) cellfun(@(x) ~isempty(x), regexp(levelNames, sprintf('%s.Trial Time.*', level)));
% getMeanLevel = @(level) cellfun(@(x) ~isempty(x), regexp(levelNames, sprintf('%s$', level)));
timeToSig = nan(numLevels, 1);
fprintf('\nNeuron: %s\n', neuronName)
for level_ind = 1:numLevels,
    fprintf('\t...%s\n', levelsOfInterest{level_ind})
    simTimeEst = mvnrnd(neuron.parEst(getTimeLevels(levelsOfInterest{level_ind})), stat.covb(getTimeLevels(levelsOfInterest{level_ind}), getTimeLevels(levelsOfInterest{level_ind})), numSim)';
%     simMeanEst = mvnrnd(neuron.parEst(getMeanLevels(levelsOfInterest{level_ind})), stat.covb(getMeanLevel(levelsOfInterest{level_ind}), getMeanLevel(levelsOfInterest{level_ind})), numSim)';
    timeEst = gam.bsplines{1}.unique_basis * gam.bsplines{1}.constraint * simTimeEst;
%     timeEst = simMeanEst + timeEst;
    timeEstCI = quantile(timeEst, [0.025 0.975], 2);
    time = gam.bsplines{1}.x;
    
    minTime = min(time(find(timeEstCI(:, 1) > 0, 1, 'first')), time(find(timeEstCI(:, 2) < 0, 1, 'first')));
    if ~isempty(minTime),
       timeToSig(level_ind) = minTime; 
    end
end
end