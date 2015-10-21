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
%% Compute normalized preparatory period
sessionPrepTime = cellfun(@(x) x('Preparation Time').data, behaviorJob, 'UniformOutput', false);
prepAll = [sessionPrepTime{:}];

monkey = cellfun(@(x) x('Monkey').data, behaviorJob, 'UniformOutput', false);
[monkey_ind, monkeyNames] = grp2idx([monkey{:}]);
monkeyMeanPrep = accumarray(monkey_ind, prepAll, [], @nanmean);
monkeyStdPrep = accumarray(monkey_ind, prepAll, [], @nanstd);

normFun = @(x, m) (x - monkeyMeanPrep(ismember(monkeyNames, m))) / monkeyStdPrep(ismember(monkeyNames, m));

normPrep = cellfun(normFun, sessionPrepTime, monkey, 'UniformOutput', false);
for k = 1:length(behavior),
    cov.data = normPrep{k};
    behavior{k}('Normalized Preparation Time') = cov;
end
clear cov;
%% Split prep period into thirds
sessionPrepTime = cellfun(@(x) x('Preparation Time').data, behaviorJob, 'UniformOutput', false);
prepAll = [sessionPrepTime{:}];

monkey = cellfun(@(x) x('Monkey').data, behaviorJob, 'UniformOutput', false);
[monkey_ind, monkeyNames] = grp2idx([monkey{:}]);

for k = 1:length(monkeyNames),
    quantByMonkey{k} = quantile(prepAll(monkey_ind == k), [0 (1/3) (2/3) 1]);
    quantByMonkey{k}(1) = quantByMonkey{k}(1) - 1;
    quantByMonkey{k}(end) = quantByMonkey{k}(end) + 1;
end

for k = 1:length(behavior),
    cov.data = normBySession(sessionPrepTime{k}, quantByMonkey{ismember(monkeyNames, behavior{k}('Monkey').data)});
    behavior{k}('Preparation Time Indicator') = cov;
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

