function [saveDir, p, obsDiff, randDiff] = RuleBy_firingRatePermutationAnalysis(sessionName, permutationParams, covInfo)
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
saveDir = sprintf('%s/permutationAnalysis/RuleBy-%s/', timePeriodDir, regexprep(permutationParams.covariateOfInterest, '\s+', '-'));
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
levelsID = 1:length(levels);
levelsID(baseline_ind) = [];
numLevels = length(levelsID);

randDiff = nan(numLevels, permutationParams.numRand, numNeurons);
obsDiff = nan(numLevels, numNeurons);
obs = nan(numLevels+1, numNeurons);
p = nan(numLevels, numNeurons);
neuronNames = cell(numNeurons, 1);
comparisonNames = cell(numLevels, 1);

ruleLabels = spikeCov('Rule');
ruleLevels = covInfo('Rule').levels;
ruleBaselineLevel = covInfo('Rule').baselineLevel;
ruleBaseline_ind = find(ismember(ruleLevels, ruleBaselineLevel));
ruleLevelsID = 1:length(ruleLevels);

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
colorID = find(ismember(ruleLevels, 'Color'));
orientationID = find(ismember(ruleLevels, 'Orientation'));
for level_ind = 1:numLevels,
    comparisonNames{level_ind} = sprintf('Orientation Rule - Color Rule @ %s', levels{levelsID(level_ind)});
    fprintf('\nComparison: %s\n', comparisonNames{level_ind});
    
    % Comparison Level
    curLevelColor_ind = (labels == levelsID(level_ind)) & (ruleLabels == colorID);
    curLevelOrientation_ind = (labels == levelsID(level_ind)) & (ruleLabels == orientationID);
    curLevelTrials_color = unique(trialID(curLevelColor_ind));
    curLevelTrials_orientation = unique(trialID(curLevelOrientation_ind));
    
    % Baseline Level
    baselineLevelColor_ind = (labels == baseline_ind) & (ruleLabels == colorID);
    baselineLevelOrientation_ind = (labels == baseline_ind) & (ruleLabels == orientationID);
    baselineLevelTrials_color = unique(trialID(baselineLevelColor_ind));
    baselineLevelTrials_orientation = unique(trialID(baselineLevelOrientation_ind));
    
    obs(level_ind, :) = 1000 * (nanmean(spikes(curLevelOrientation_ind, :)) - nanmean(spikes(curLevelColor_ind, :)));
    obs(end, :) = 1000 * (nanmean(spikes(baselineLevelOrientation_ind, :)) - nanmean(spikes(baselineLevelColor_ind, :)));
    obsDiff(level_ind, :) = abs(obs(level_ind, :)) - abs(obs(end, :));
    
    orientationData = cat(1, curLevelTrials_orientation, baselineLevelTrials_orientation);
    orientationGroup1_ind = 1:length(curLevelTrials_orientation);
    orientationGroup2_ind = length(curLevelTrials_orientation)+1:size(orientationData, 1);
    
    colorData = cat(1, curLevelTrials_color, baselineLevelTrials_color);
    colorGroup1_ind = 1:length(curLevelTrials_color);
    colorGroup2_ind = length(curLevelTrials_color)+1:size(colorData, 1);
    
    parfor rand_ind = 1:permutationParams.numRand,
        if (mod(rand_ind, 100) == 0)
            fprintf('\t\tRand #%d...\n', rand_ind);
        end
        
        orientationPerm_ind = randperm(size(orientationData, 1));
        colorPerm_ind = randperm(size(colorData, 1));
        
        orientationRandData1 = s.Value(ismember(trialID, orientationData(orientationPerm_ind(orientationGroup1_ind))), :);
        orientationRandData2 = s.Value(ismember(trialID, orientationData(orientationPerm_ind(orientationGroup2_ind))), :);
        colorRandData1 = s.Value(ismember(trialID, colorData(colorPerm_ind(colorGroup1_ind))), :);
        colorRandData2 = s.Value(ismember(trialID, colorData(colorPerm_ind(colorGroup2_ind))), :);
        
        randDiff(level_ind, rand_ind, :) = abs(1000 * (nanmean(orientationRandData1) - nanmean(colorRandData1))) - ...
            abs(1000 * (nanmean(orientationRandData2) - nanmean(colorRandData2)));
    end
    for neuron_ind = 1:numNeurons,
        % Uppper tailed test
        p(level_ind, neuron_ind) = (sum((randDiff(level_ind, :, neuron_ind)) >= (obsDiff(level_ind, neuron_ind)), 2)) / (permutationParams.numRand);
        p(p == 0) = 1 / permutationParams.numRand;
        p(p == 1) = (permutationParams.numRand - 1) / permutationParams.numRand;
        p(isnan(obsDiff)) = NaN;
        p(squeeze(all(isnan(randDiff), 2))) = NaN;
    end
    
end

fprintf('\nSaving... : %s\n', saveFileName);
save(saveFileName, 'obs', 'levels', 'obsDiff', 'randDiff', 'p', 'comparisonNames', 'monkeyName', ...
    'neuronNames', 'avgFiringRate', 'permutationParams', 'neuronBrainArea', '-v7.3');

end