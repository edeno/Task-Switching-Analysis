function [timeToHalfMax, levelsOfInterest] = getFirstHalfWidthMax(neuronName, covOfInterest, timePeriod, model, varargin)
numSim = 1e4;
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
timeToHalfMax = nan(numLevels, numSim);
time = gam.bsplines{1}.x;
fprintf('\nNeuron: %s\n', neuronName)
for level_ind = 1:numLevels,
    fprintf('\t...%s\n', levelsOfInterest{level_ind})
    time_ind = getTimeLevels(levelsOfInterest{level_ind});
    simTimeEst = mvnrnd(neuron.parEst(time_ind), stat.covb(time_ind, time_ind), numSim)';
    mean_ind = getMeanLevel(levelsOfInterest{level_ind});
    simMeanEst = mvnrnd(neuron.parEst(mean_ind), stat.covb(mean_ind, mean_ind), numSim)';
    timeEst = gam.bsplines{1}.unique_basis * gam.bsplines{1}.constraint * simTimeEst;
    timeEst = bsxfun(@plus, simMeanEst, timeEst);
    rangeEst = quantile(timeEst, [0, 1], 1);
    halfMaxEst = rangeEst(1, :) + diff(rangeEst, [], 1) / 2;
    thresh = bsxfun(@gt, timeEst, halfMaxEst);
    thresh = thresh(2:end,:) & diff(timeEst, [], 1) > 0; % consider only increasing crossings
    thresh = double(thresh);
    thresh(thresh == 0) = NaN;
    thresh = bsxfun(@times, thresh, time(2:end));
    timeToHalfMax(level_ind, :) = min(thresh, [], 1);
end
end