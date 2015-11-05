%% Extract Behavior
function ExtractBehavior(isLocal)
%% Setup
% Load Common Parameters
mainDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', mainDir), 'sessionNames', 'trialInfo', ...
    'numErrorLags', 'numRepetitionLags', 'reactBounds', 'encodeMap', 'covInfo');

%% Get Behavior
behaviorJob = [];
fprintf('\n\nExtracting Behavior\n');
if isLocal,
    % Run Locally
    for session_ind = 1:length(sessionNames),
        behaviorJob{session_ind} = ExtractBehaviorBySession(sessionNames{session_ind}, ...
            reactBounds, ...
            trialInfo, ...
            covInfo, ...
            encodeMap, ...
            numErrorLags, ...
            numRepetitionLags);
    end
    behavior = behaviorJob;
else
    % Use Cluster
    args = cellfun(@(x) {x; ...
        reactBounds; ...
        trialInfo, ...
        covInfo, ...
        encodeMap, ...
        numErrorLags, ...
        numRepetitionLags}', ...
        sessionNames, 'UniformOutput', false);
    behaviorJob = TorqueJob('ExtractBehaviorBySession', args, ...
        'walltime=1:00:00,mem=16GB');
    % Make sure the job has finished
    waitMatorqueJob(behaviorJob);
    % Fetch Outputs from the jobs
    behavior = gatherMatorqueOutput(behaviorJob);
end
%% Compute normalized preparatory period - Normalize by Monkey and by Rule
behaviorAll = mergeMap(behavior);
prepTime = behaviorAll('Preparation Time');
session = behaviorAll('Session Name');
monkey = grp2idx(behaviorAll('Monkey'));
monkeyID = unique(monkey);
normPrepTime = nan(size(prepTime));

normalize = @(x) (x - nanmean(x)) / 50; % Scale units to 50 ms of preparation time

for monkey_ind = 1:length(monkeyID),
        filter_ind = monkey == monkeyID(monkey_ind);
        normPrepTime(filter_ind) = normalize(prepTime(filter_ind));
end

for k = 1:length(sessionNames),
    behavior{k}('Normalized Preparation Time') = normPrepTime(ismember(session, sessionNames{k}));
end
%% Split prep period into thirds
numIntervals = 3;
for monkey_ind = 1:length(monkeyID),
        filter_ind = monkey == monkeyID(monkey_ind);
        quantByMonkey = quantile(prepTime(filter_ind), [0:numIntervals] / numIntervals);
        quantByMonkey(end) = quantByMonkey(end) + 1;
        prepTimeIndicator(filter_ind) = histc(prepTime(filter_ind), quantByMonkey);
end

for k = 1:length(sessionNames),
    behavior{k}('Preparation Time Indicator') = prepTimeIndicator(ismember(session, sessionNames{k}));
end
%% Get total number of neurons
numTotalNeurons = cellfun(@(x) x('Number of Neurons'), behaviorJob, 'UniformOutput', false);
numTotalNeurons = sum([numTotalNeurons{:}]);
numTotalLFPs = cellfun(@(x) x('Number of LFPs'), behaviorJob, 'UniformOutput', false);
numTotalLFPs = sum([numTotalLFPs{:}]);
%% Save everything
saveFileName = sprintf('%s/Behavior/behavior.mat', mainDir);
fprintf('\nSaving to %s...\n', saveFileName);
% Save Behavior
save(saveFileName, 'behavior');

% Append Information to ParamSet
saveFileName = sprintf('%s/paramSet.mat', mainDir);
save(saveFileName, 'numTotalNeurons', 'numTotalLFPs', '-append');
end
function [quantile_ind] = normBySession(sessionPrepTime, quantBounds)
[~, quantile_ind] = histc(sessionPrepTime, quantBounds);
quantile_ind(isnan(sessionPrepTime)) = NaN;
end

