function [meanSpiking, time, spikesSample, cInfo] = getModelSim(neuronName, timePeriod, model, covOfInterest, varargin)
inParser = inputParser;
inParser.addRequired('neuronName', @ischar);
inParser.addRequired('timePeriod', @ischar);
inParser.addRequired('model', @ischar);
inParser.addRequired('covOfInterest', @ischar);
inParser.addParameter('includeIncorrect', false, @islogical);
inParser.addParameter('includeFixationBreaks', false, @islogical);
inParser.addParameter('includeTimeBeforeZero', false, @islogical);
inParser.addParameter('sigma', 20, @isnumeric);
inParser.addParameter('numSamples', 50, @isnumeric);

inParser.parse(neuronName, timePeriod, model, covOfInterest, varargin{:});
params = inParser.Results;

%%
workingDir = getWorkingDir();
modelsDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
load(sprintf('%s/modelList.mat', modelsDir));
timePeriodDir = sprintf('%s/Processed Data/%s/', workingDir, params.timePeriod);
load(sprintf('%s/paramSet.mat', workingDir), 'covInfo');

splitName = strsplit(neuronName, '-');
sessionName = splitName{1};
curWire = str2double(splitName{2});
curUnit = str2double(splitName{3});

load(sprintf('%s/%s/%s_GAMfit.mat', modelsDir, modelList(model), sessionName), 'gam', 'designMatrix');
d = dir(sprintf('%s/%s/*_neuron_%s_%d_%d_GAMfit.mat', modelsDir, modelList(model), sessionName, curWire, curUnit));
load(sprintf('%s/%s/%s',  modelsDir, modelList(model), d.name))
%%
if ~params.includeTimeBeforeZero,
    good_ind = gam.trialTime >= 0;
    designMatrix = designMatrix(good_ind, :);
    gam.trialID = gam.trialID(good_ind);
    gam.trialTime = gam.trialTime(good_ind);
end

firingRate = exp(designMatrix * gam.constraints' * [neuron.parEst]) * 1000;

dt = 1E-3;
curSpikes = simPoisson(firingRate, dt);

spikeCov = getSpikeCov(timePeriodDir, sessionName, params);

%%
trials = unique(gam.trialID);
time_ind = grp2idx(gam.trialTime);
time = unique(gam.trialTime);
timeLimits = quantile(time, [0 1]);

t = cell(length(trials), 1);
spikesByTrial = cell(length(trials), 1);
levelsByTrial = nan(length(trials), 1);
l = 300;
x = linspace(-l / 2, l / 2, l);
gaussFilter = exp(-x .^ 2 / (2 * params.sigma ^ 2));
gaussFilter = gaussFilter / sum (gaussFilter); % normalize

levelsByCov = spikeCov(covOfInterest);
levels = unique(levelsByCov);

for trial = 1:length(trials),
    i = (gam.trialID == trials(trial));
    numPad = timeLimits - quantile(gam.trialTime(i), [0 1]);
    t{trial} = [nan(numPad(1), 1); conv(curSpikes(i), gaussFilter, 'same') * 1E3; nan(numPad(2), 1)];
    levelsByTrial(trial) = unique(levelsByCov(i));
    spikesByTrial{trial} = time(find(curSpikes(i)));
end

meanSpiking = nan(length(levels), length(time));
spikesSample = cell(length(levels), 1);

for level_ind = 1:length(levels),
    curTrials_ind = find(levelsByTrial == levels(level_ind));
    meanSpiking(level_ind, :) = nanmean([t{curTrials_ind}], 2);
    s = spikesByTrial(sort(curTrials_ind(randperm(length(curTrials_ind), params.numSamples))));
    s_ind = cellfun(@(x,y) repmat(x, size(y)), num2cell(1:params.numSamples)', s, 'UniformOutput', false);
    spikesSample{level_ind} = [cat(1, s{:}), cat(1, s_ind{:})];
end

cInfo = covInfo(covOfInterest);
end
function [spikeCov] = getSpikeCov(timePeriodDir, sessionName, params)
dataFileName = sprintf('%s/SpikeCov/%s_SpikeCov.mat', timePeriodDir, sessionName);
load(dataFileName);
covNames = spikeCov.keys;

if ~params.includeIncorrect
    for cov_ind = 1:length(covNames),
        if ~spikeCov.isKey(covNames{cov_ind}), continue; end;
        cov = spikeCov(covNames{cov_ind});
        spikeCov(covNames{cov_ind}) = cov(isCorrect, :);
    end
    spikes(~isCorrect, :) = [];
    trialTime(~isCorrect) = [];
    trialID(~isCorrect) = [];
    percentTrials(~isCorrect) = [];
    isAttempted(~isCorrect) = [];
end

if ~params.includeTimeBeforeZero,
    isBeforeZero = trialTime < 0;
    for cov_ind = 1:length(covNames),
        if ~spikeCov.isKey(covNames{cov_ind}), continue; end;
        cov = spikeCov(covNames{cov_ind});
        spikeCov(covNames{cov_ind}) = cov(~isBeforeZero, :);
    end
    spikes(isBeforeZero, :) = [];
    trialTime(isBeforeZero) = [];
    trialID(isBeforeZero) = [];
    percentTrials(isBeforeZero) = [];
    isAttempted(isBeforeZero) = [];
end

if ~params.includeFixationBreaks
    for cov_ind = 1:length(covNames),
        if ~spikeCov.isKey(covNames{cov_ind}), continue; end;
        cov = spikeCov(covNames{cov_ind});
        spikeCov(covNames{cov_ind}) = cov(isAttempted, :);
    end
    spikes(~isAttempted, :) = [];
    trialTime(~isAttempted) = [];
    trialID(~isAttempted) = [];
    percentTrials(~isAttempted) = [];
end
end