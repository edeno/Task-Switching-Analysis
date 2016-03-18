function [saveDir, p, obsDiff, randDiff] = firingRatePermutationAnalysis(sessionName, permutationParams, covInfo)
%% Log parameters
fprintf('\n------------------------\n');
fprintf('\nSession: %s\n', sessionName);
fprintf('\nDate: %s\n \n', datestr(now));
fprintf('\nPopulation Analysis Parameters\n');
fprintf('\t covariateOfInterest: %s\n', permutationParams.covariateOfInterest);
fprintf('\t timePeriod: %s\n', permutationParams.timePeriod);
fprintf('\t overwrite: %d\n', permutationParams.overwrite);
fprintf('\t includeIncorrect: %d\n', permutationParams.includeIncorrect);
fprintf('\t includeTimeBeforeZero: %d\n', permutationParams.includeTimeBeforeZero);
fprintf('\t numRand: %d\n', permutationParams.numRand);
fprintf('\t numCores: %d\n', permutationParams.numCores);
%% Get directories
mainDir = getWorkingDir();
timePeriodDir = sprintf('%s/Processed Data/%s/', mainDir, permutationParams.timePeriod);
%% Setup Save File
saveDir = sprintf('%s/populationAnalysis/%s/', timePeriodDir, regexprep(permutationParams.covariateOfInterest, '\s+', '-'));
if ~exist(saveDir, 'dir'),
    mkdir(saveDir);
end
saveFileName = sprintf('%s/%s_permutationAnalysis.mat', saveDir, sessionName);

if exist(saveFileName, 'file') && ~permutationParams.overwrite,
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

wireNumber = num2cell(wireNumber);
unitNumber = num2cell(unitNumber);
covNames = spikeCov.keys;

fprintf('\nNumber of Neurons: %d\n', numNeurons);

if ~permutationParams.includeIncorrect
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

if ~permutationParams.includeTimeBeforeZero,
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

if ~permutationParams.includeFixationBreaks
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

labels = spikeCov(permutationParams.covariateOfInterest);
levels = covInfo(permutationParams.covariateOfInterest).levels;
baselineLevel = covInfo(permutationParams.covariateOfInterest).baselineLevel;
baseline_ind = find(ismember(levels, baselineLevel));
levels(baseline_ind) = []; % remove baseline level
numLevels = length(levels);

randDiff = nan(numLevels, permutationParams.numRand, numNeurons);
obsDiff = nan(numLevels, numNeurons);
p = nan(numLevels, numNeurons);
neuronNames = cell(numNeurons, 1);
comparisonNames = cell(numLevels, 1);

for neuron_ind = 1:numNeurons,
    neuronNames{neuron_ind} = sprintf('%s-%d-%d', sessionName, wireNumber{neuron_ind}, unitNumber{neuron_ind});
end
avgFiringRate = nanmean(spikes, 1) * 1000;

%% Create matlab pool
if permutationParams.numCores > 0,
    fprintf('\nCreate matlab pool...\n');
    myCluster = parcluster('local');
    tempDir = tempname;
    mkdir(tempDir);
    myCluster.JobStorageLocation = tempDir;  % points to TMPDIR
    
    poolobj = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(poolobj)
        parpool(myCluster, min([numNeurons, permutationParams.numCores, myCluster.NumWorkers]));
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
    obsDiff(level_ind, :) = 1000 * (nanmean(spikes(labels == level_ind, :)) - nanmean(spikes(labels == baseline_ind, :)));
    parfor rand_ind = 1:permutationParams.numRand,
        perm_ind = randperm(size(data, 1));
        randData1 = s.Value(ismember(trialID, perm_ind(group1_ind)), :);
        randData2 = s.Value(ismember(trialID, perm_ind(group2_ind)), :);
        randDiff(level_ind, rand_ind, :) = 1000 * (nanmean(randData1) - nanmean(randData2));
    end
    for neuron_ind = 1:numNeurons,
        p(level_ind, neuron_ind) = (sum(abs(randDiff(level_ind, :, neuron_ind)) >= abs(obsDiff(level_ind, neuron_ind)), 2)) / (permutationParams.numRand);
        p(p == 0) = 1 / permutationParams.numRand;
        p(p == 1) = (permutationParams.numRand - 1) / permutationParams.numRand;
    end
    
end

save(saveFileName, 'obsDiff', 'randDiff', 'p', 'comparisonNames', 'monkeyName', ...
    'neuronNames', 'avgFiringRate', 'permutationParams', 'neuronBrainArea', '-v7.3');

end