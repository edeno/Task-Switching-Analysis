function [saveDir, p, obsDiff, randDiff] = firingRatePermutationAnalysis(sessionName, popParams, covInfo)
%% Log parameters
fprintf('\n------------------------\n');
fprintf('\nSession: %s\n', sessionName);
fprintf('\nDate: %s\n \n', datestr(now));
fprintf('\nPopulation Analysis Parameters\n');
fprintf('\t covariateOfInterest: %s\n', popParams.covariateOfInterest);
fprintf('\t timePeriod: %s\n', popParams.timePeriod);
fprintf('\t overwrite: %d\n', popParams.overwrite);
fprintf('\t includeIncorrect: %d\n', popParams.includeIncorrect);
fprintf('\t includeTimeBeforeZero: %d\n', popParams.includeTimeBeforeZero);
fprintf('\t numRand: %d\n', popParams.numRand);
fprintf('\t numCores: %d\n', popParams.numCores);
%% Get directories
mainDir = getWorkingDir();
timePeriodDir = sprintf('%s/Processed Data/%s/', mainDir, popParams.timePeriod);
%% Setup Save File
saveDir = sprintf('%s/populationAnalysis/%s/', timePeriodDir, regexprep(popParams.covariateOfInterest, '\s+', '-'));
if ~exist(saveDir, 'dir'),
    mkdir(saveDir);
end
saveFileName = sprintf('%s/%s_%s_popAnalysis.mat', saveDir, sessionName);

if exist(saveFileName, 'file') && ~popParams.overwrite,
    p = []; obsDiff = []; randDiff = [];
    fprintf('File %s already exists. Skipping.\n', saveFileName);
    return;
end
%%  Load Data for Fitting
fprintf('\nLoading data...\n');
dataFileName = sprintf('%s/SpikeCov/%s_SpikeCov.mat', timePeriodDir, sessionName);
load(dataFileName);

% For some reason, matlab freaks out if you don't do this
wireNumber = double(wire_number);
unitNumber = double(unit_number);

monkeyName = regexp(sessionName, '(cc)|(isa)|(ch)|(test)', 'match');
monkeyName = monkeyName{:};

numTrials = length(unique(trialID));
numPFC = sum(ismember(neuronBrainArea, 'dlPFC'));
numACC = sum(ismember(neuronBrainArea, 'ACC'));

wireNumber = num2cell(wireNumber);
unitNumber = num2cell(unitNumber);
covNames = spikeCov.keys;

fprintf('\nNumber of Neurons: %d\n', numNeurons);

if ~popParams.includeIncorrect
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

if ~popParams.includeTimeBeforeZero,
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

if ~popParams.includeFixationBreaks
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

labels = spikeCov(popParams.covariateOfInterest);
levels = covInfo(popParams.covariateOfInterest).levels;
baselineLevel = covInfo(popParams.covariateOfInterest).baselineLevel;
baseline_ind = find(ismember(levels, baselineLevel));
levels(baseline_ind) = []; % remove baseline level
numLevels = length(levels);

randDiff = nan(numLevels, popParams.numRand, numNeurons);
obsDiff = nan(numLevels, numNeurons);
p = nan(numLevels, numNeurons);
neuronNames = cell(numNeurons, 1);
comparisonNames = cell(numLevels, 1);

for neuron_ind = 1:numNeurons,
    neuronNames{neuron_ind} = sprintf('%s-%d-%d', sessionName, wireNumber{neuron_ind}, unitNumber{neuron_ind});
end
avgFiringRate = nanmean(spikes, 1);

%% Create matlab pool
if popParams.numCores > 0,
    fprintf('\nCreate matlab pool...\n');
    myCluster = parcluster('local');
    tempDir = tempname;
    mkdir(tempDir);
    myCluster.JobStorageLocation = tempDir;  % points to TMPDIR
    
    poolobj = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(poolobj)
        parpool(myCluster, min([numNeurons, popParams.numCores, myCluster.NumWorkers]));
    end
    
    %Transfer static assets to each worker only once
    fprintf('\nTransferring static assets to each worker...\n');
    if verLessThan('matlab', '8.6'),
        s = WorkerObjWrapper(spikes);
    else
        s = parallel.pool.Constant(spikes);
    end
    fprintf('\nFinished transferring static assets...\n');
else
    s.Value = spikes;
end

%%

for level_ind = 1:numLevels,
    comparisonNames{level_ind} = sprintf('%s - %s', levels{level_ind}, baselineLevel);
    fprintf('\nComparison: %s\n', comparisonNames{level_ind});
    curLevelTrials = unique(trialID(labels == level_ind));
    curBaselineTrials = unique(trialID(labels == baseline_ind));
    data = cat(1, curLevelTrials, curBaselineTrials);
    group1_ind = 1:length(curLevelTrials);
    group2_ind = length(curLevelTrials)+1:size(data, 1);
    obsDiff(level_ind, :) = nanmean(spikes(labels == level_ind, :)) - nanmean(spikes(labels == baseline_ind, :));
    parfor rand_ind = 1:popParams.numRand,
        perm_ind = randperm(size(data, 1));
        randData1 = s.Value(ismember(trialID, perm_ind(group1_ind)), :);
        randData2 = s.Value(ismember(trialID, perm_ind(group2_ind)), :);
        randDiff(level_ind, rand_ind, :) = nanmean(randData1) - nanmean(randData2);
    end
    for neuron_ind = 1:numNeurons,
        p(level_ind, neuron_ind) = sum(abs(randDiff(level_ind, :, neuron_ind)) >= abs(obsDiff(level_ind, neuron_ind)), 2) / popParams.numRand;
    end
    
end

save(saveFileName, 'obsDiff', 'randDiff', 'p', 'comparisonNames', 'neuronNames', 'avgFiringRate', '-v7.3');

end