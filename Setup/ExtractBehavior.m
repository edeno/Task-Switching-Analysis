%% Extract Behavior
function ExtractBehavior(isLocal)
%% Setup
% Load Common Parameters
main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), 'session_names', 'data_info', 'trial_info', 'numSessions');

% Set Acceptable Reaction Times
react_bounds = [100 313];
%% Get Behavior
behaviorJob = [];

if isLocal,
    % Run Locally
    for session_ind = 1:length(session_names),
        behaviorJob{session_ind} = SetupBehavior_cluster(session_names{session_ind}, ...
            react_bounds, ...
            session_ind, ...
            trial_info);
    end
    behavior = [behaviorJob{:}];
else
    % Use Cluster
    args = cellfun(@(x) {x; ...
        react_bounds; ...
        find(ismember(session_names, x)), ...
        trial_info}', ...
        session_names, 'UniformOutput', false);
    behaviorJob = TorqueJob('SetupBehavior_cluster', args, ...
        'walltime=1:00:00,mem=16GB');
    % Make sure the job has finished
    waitMatorqueJob(behaviorJob);
    % Fetch Outputs from the jobs
    behavior = cellfun(@(x) x.output, behaviorJob.tasks);
end
%% Compute normalized preparatory period
prep = cat(1, behavior.Prep_Time);
norm_prep = nan(size(prep));
monk = grp2idx(cat(1, behavior.monkey))';
for k = 1:max(monk)
    norm_prep(monk == k) = prep(monk == k) - nanmean(prep(monk == k));
end

norm_prep = norm_prep ./ (nanstd(norm_prep));

for k = 1:length(behavior)
    behavior(k).Normalized_Prep_Time = norm_prep(cat(1, behavior.day) == k);
end

%% Split prep period into thirds
prep = cat(1, behavior.Prep_Time);
indicator_prep = nan(size(prep));
monk = grp2idx(cat(1, behavior.monkey))';

for k = 1:max(monk)
    prep_quant_bounds = [-inf quantile(prep(monk == k), (1:(3-1))/3) inf];
    [~, bin] = histc(prep(monk == k), prep_quant_bounds);
    bin(bin == 0) = NaN;
    indicator_prep(monk == k) = bin;
end

for k = 1:length(behavior)
    behavior(k).Indicator_Prep_Time = indicator_prep(cat(1, behavior.day) == k);
end


%% Get total number of neurons
numTotalNeurons = sum(cat(1, behavior.numNeurons));
numTotalLFPs = sum(cat(1, behavior.numLFPs));

%% Save everything
save_file_name = sprintf('%s/Behavior/behavior.mat', main_dir);
fprintf('\nSaving to %s...\n', save_file_name);
% Save Behavior
save(save_file_name, 'behavior');

% Append Information to ParamSet
save_file_name = sprintf('%s/paramSet.mat', main_dir);
save(save_file_name, 'numTotalNeurons', 'numTotalLFPs', 'react_bounds', '-append');
end
