function [sigChangeTimes, levelsOfInterest] = getChangeTimes(neuronName, covOfInterest, timePeriod, model, varargin)
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
fprintf('\nNeuron: %s\n', neuronName)
time = gam.bsplines{1}.x;
time = time(51:end); % exclude first 50 ms because of potential edge effects
sigChangeTimes = cell(numLevels, 1);
for level_ind = 1:numLevels,
    fprintf('\t...%s\n', levelsOfInterest{level_ind})
    time_ind = getTimeLevels(levelsOfInterest{level_ind});
    simTimeEst = mvnrnd(neuron.parEst(time_ind), stat.covb(time_ind, time_ind), numSim)';
    timeEst = gam.bsplines{1}.unique_basis * gam.bsplines{1}.constraint * simTimeEst;
    timeEst = timeEst(51:end, :); % exclude first 50 ms because of potential edge effects
    changeTimes = diff(timeEst, [], 1);
    changeTimesCI = quantile(changeTimes, pThresh * [1 -1] + [0 1], 2);
    sigChangeTimes{level_ind} = time(changeTimesCI(:, 1) > 0 || changeTimesCI(:, 2) < 0); % Only increases in firing rate
end
end