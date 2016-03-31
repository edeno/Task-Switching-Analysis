function [saveDir, p, obsDiff, randDiff] = RuleBy_correlationAnalysis(sessionName, correlationParams, covInfo)
%% Log parameters
fprintf('\n------------------------\n');
fprintf('\nSession: %s\n', sessionName);
fprintf('\nDate: %s\n \n', datestr(now));
fprintf('\nCorrelation Analysis Parameters\n');
fprintf('\t covariateOfInterest: %s\n', correlationParams.covariateOfInterest);
fprintf('\t timePeriod: %s\n', correlationParams.timePeriod);
fprintf('\t overwrite: %d\n', correlationParams.overwrite);
fprintf('\t includeIncorrect: %d\n', correlationParams.includeIncorrect);
fprintf('\t includeTimeBeforeZero: %d\n', correlationParams.includeTimeBeforeZero);
%% Get directories
mainDir = getWorkingDir();
timePeriodDir = sprintf('%s/Processed Data/%s/', mainDir, correlationParams.timePeriod);
%% Setup Save File
saveDir = sprintf('%s/correlationAnalysis/RuleBy-%s/', timePeriodDir, regexprep(correlationParams.covariateOfInterest, '\s+', '-'));
if ~exist(saveDir, 'dir'),
    mkdir(saveDir);
end
saveFileName = sprintf('%s/%s_correlationAnalysis.mat', saveDir, sessionName);

if exist(saveFileName, 'file') && ~correlationParams.overwrite,
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

if ~correlationParams.includeIncorrect
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

if ~correlationParams.includeTimeBeforeZero,
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

if ~correlationParams.includeFixationBreaks
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

labels = spikeCov(correlationParams.covariateOfInterest);
levels = covInfo(correlationParams.covariateOfInterest).levels;
baselineLevel = covInfo(correlationParams.covariateOfInterest).baselineLevel;
baseline_ind = find(ismember(levels, baselineLevel));
levelsID = 1:length(levels);
levelsID(baseline_ind) = [];
numLevels = length(levelsID);

obsDiff = nan(numLevels, 2, numNeurons);

neuronNames = cell(numNeurons, 1);
comparisonNames = cell(numLevels, 1);

ruleLabels = spikeCov('Rule');
ruleLevels = covInfo('Rule').levels;

for neuron_ind = 1:numNeurons,
    neuronNames{neuron_ind} = sprintf('%s-%d-%d', sessionName, wireNumber{neuron_ind}, unitNumber{neuron_ind});
end
avgFiringRate = nanmean(spikes, 1) * 1000;

%%
colorID = find(ismember(ruleLevels, 'Color'));
orientationID = find(ismember(ruleLevels, 'Orientation'));
for level_ind = 1:numLevels,
    comparisonNames{level_ind} = sprintf('Orientation Rule - Color Rule @ %s', levels{levelsID(level_ind)});
    fprintf('\nComparison: %s\n', comparisonNames{level_ind});
    
    % Comparison Level
    curLevelColor_ind = (labels == levelsID(level_ind)) & (ruleLabels == colorID);
    curLevelOrientation_ind = (labels == levelsID(level_ind)) & (ruleLabels == orientationID);
    
    % Baseline Level
    baselineLevelColor_ind = (labels == baseline_ind) & (ruleLabels == colorID);
    baselineLevelOrientation_ind = (labels == baseline_ind) & (ruleLabels == orientationID);
    
    obsDiff(level_ind, 1, :) = (1000 * (nanmean(spikes(curLevelOrientation_ind, :)) - nanmean(spikes(curLevelColor_ind, :)))) ./ avgFiringRate;
    obsDiff(level_ind, 2, :) = (1000 * (nanmean(spikes(baselineLevelOrientation_ind, :)) - nanmean(spikes(baselineLevelColor_ind, :)))) ./ avgFiringRate;
     
end

fprintf('\nSaving... : %s\n', saveFileName);
save(saveFileName, 'obsDiff', 'comparisonNames', 'monkeyName', ...
    'neuronNames', 'avgFiringRate', 'correlationParams', 'neuronBrainArea', '-v7.3');

end