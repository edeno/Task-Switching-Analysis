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
saveDir = sprintf('%s/permutationAnalysis/%s/', timePeriodDir, regexprep(permutationParams.covariateOfInterest, '\s+', '-'));
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
numHist = size(labels, 2);
levels = covInfo(permutationParams.covariateOfInterest).levels;
levels = reshape(levels, [], numHist);
baselineLevel = covInfo(permutationParams.covariateOfInterest).baselineLevel;
if ~iscell(baselineLevel),
    baselineLevel = {baselineLevel};
end
baselineLevel = reshape(baselineLevel, [], numHist);
[baseline_ind, ~] = find(ismember(levels, baselineLevel));
baseline_ind = unique(baseline_ind);
levelsID = 1:size(levels, 1);
levelsID(baseline_ind) = [];
numLevels = length(levelsID);

randDiff = nan(numLevels, numHist, permutationParams.numRand, numNeurons);
obsDiff = nan(numLevels, numHist, numNeurons);
obs = nan(numLevels + 1, numHist, numNeurons);
p = nan(numLevels, numHist, numNeurons);
neuronNames = cell(numNeurons, 1);
comparisonNames = cell(numLevels, numHist, 1);

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
for hist_ind = 1:numHist,
    obs(end, hist_ind, :) = nanmean(spikes(labels(:, hist_ind) == baseline_ind, :)) * 1000;
    for level_ind = 1:numLevels,
        comparisonNames{level_ind, hist_ind} = sprintf('%s - %s', levels{levelsID(level_ind), hist_ind}, baselineLevel{hist_ind});
        fprintf('\nComparison: %s\n', comparisonNames{level_ind, hist_ind});
        curLevelTrials = unique(trialID(labels(:, hist_ind) == levelsID(level_ind)));
        curBaselineTrials = unique(trialID(labels(:, hist_ind) == baseline_ind));
        data = cat(1, curLevelTrials, curBaselineTrials);
        group1_ind = 1:length(curLevelTrials);
        group2_ind = length(curLevelTrials)+1:size(data, 1);
        obs(level_ind, hist_ind, :) = nanmean(spikes(labels(:, hist_ind) == levelsID(level_ind), :)) * 1000;
        obsDiff(level_ind, hist_ind, :) = obs(level_ind, hist_ind, :) - obs(end, hist_ind, :);
        
        parfor rand_ind = 1:permutationParams.numRand,
            if (mod(rand_ind, 100) == 0)
                fprintf('\t\tRand #%d...\n', rand_ind);
            end
            perm_ind = randperm(size(data, 1));
            randData1 = s.Value(ismember(trialID, data(perm_ind(group1_ind))), :);
            randData2 = s.Value(ismember(trialID, data(perm_ind(group2_ind))), :);
            randDiff(level_ind, hist_ind, rand_ind, :) = 1000 * (nanmean(randData1) - nanmean(randData2));
        end
        for neuron_ind = 1:numNeurons,
            p(level_ind, hist_ind, neuron_ind) = (sum(abs(randDiff(level_ind, hist_ind, :, neuron_ind)) ...
                >= abs(obsDiff(level_ind, hist_ind, neuron_ind)), 3)) ...
                / (permutationParams.numRand);
        end
        
    end
    
end

p(p == 0) = 1 / permutationParams.numRand;
p(p == 1) = (permutationParams.numRand - 1) / permutationParams.numRand;
p(isnan(obsDiff)) = NaN;
p(squeeze(all(isnan(randDiff), 2))) = NaN;


randDiff = reshape(randDiff, [numLevels * numHist, permutationParams.numRand, numNeurons]);
obsDiff = reshape(obsDiff, [numLevels * numHist, numNeurons]);
obs = reshape(obs, [(numLevels + 1) * numHist, numNeurons]);
p = reshape(p, [numLevels * numHist, numNeurons]);
comparisonNames = reshape(comparisonNames, [numLevels * numHist, 1]);

fprintf('\nSaving... : %s\n', saveFileName);
save(saveFileName, 'obs', 'levels', 'obsDiff', 'randDiff', 'p', 'comparisonNames', 'monkeyName', ...
    'neuronNames', 'avgFiringRate', 'permutationParams', 'neuronBrainArea', '-v7.3');

end