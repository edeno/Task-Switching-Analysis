function [timeToSig, levelsOfInterest] = getFirstSigTime(neuronName, covOfInterest, timePeriod, model, varargin)
numSim = 1e4;
pThresh = 1e-3;
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
getMeanLevel = @(level) cellfun(@(x) ~isempty(x), regexp(levelNames, sprintf('%s$', level)));
timeToSig = nan(numLevels, 1);
time = gam.bsplines{1}.x;
time = time(51:end); % exclude first 50 ms because of potential edge effects
fprintf('\nNeuron: %s\n', neuronName)
for level_ind = 1:numLevels,
    fprintf('\t...%s\n', levelsOfInterest{level_ind})
    time_ind = getTimeLevels(levelsOfInterest{level_ind});
    simTimeEst = mvnrnd(neuron.parEst(time_ind), stat.covb(time_ind, time_ind), numSim)';
    mean_ind = getMeanLevel(levelsOfInterest{level_ind});
    simMeanEst = mvnrnd(neuron.parEst(mean_ind), stat.covb(mean_ind, mean_ind), numSim)';
    timeEst = gam.bsplines{1}.unique_basis * gam.bsplines{1}.constraint * simTimeEst;
    timeEst = bsxfun(@plus, simMeanEst, timeEst);
    timeEst = timeEst(51:end, :); % exclude first 50 ms because of potential edge effects
    timeEstCI = quantile(timeEst, pThresh * [1 -1] + [0 1], 2);
    
    lowerCIFirst = time(find(timeEstCI(:, 1) > 0, 1, 'first'));
    upperCIFirst = time(find(timeEstCI(:, 2) < 0, 1, 'first'));
    minTime = min([lowerCIFirst, upperCIFirst]);
    if ~isempty(minTime),
       timeToSig(level_ind) = minTime; 
    end
end
end