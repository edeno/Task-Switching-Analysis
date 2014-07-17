%% Extract Behavior
clear all; close all; clc;

%% Setup
main_dir = '/data/home/edeno/Task Switching Analysis';
cd(main_dir);

% Find Cluster
jobMan = parcluster();
cleanupClusterJob(jobMan, 'edeno', 'finished');

% Load Common Parameters
load('paramSet.mat', 'session_names', 'data_info', 'trial_info', 'numSessions');

% Set Acceptable Reaction Times
react_bounds = [100 313];

%% Get Behavior

% Create a job to run on the cluster
behaviorJob = createJob(jobMan, 'AdditionalPaths', {data_info.script_dir}, 'AttachedFiles', {which('saveMillerlab')}, 'NumWorkersRange', [1 12]);

% Loop through Raw Data Directories
for session_ind = 1:numSessions,
    fprintf('\nProcessing session: %s ...\n', session_names{session_ind});
    createTask(behaviorJob, @SetupBehavior_cluster, 1, ...
        {session_names{session_ind}, main_dir, react_bounds, session_ind});
    
end  % End Raw Data Directories

submit(behaviorJob);

% Make sure the job has finished
fprintf('\nWaiting for sessions to finish ...\n');
wait(behaviorJob);

% Fetch Outputs from the jobs
tempOutputs = fetchOutputs(behaviorJob);
behavior = [tempOutputs{:}];

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
    prep_quant_bounds = [-inf quantile(prep(monk == k), [1/3 2/3]) inf];
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
fprintf('\nSaving ...\n');
% Save Behavior
save_file_name = sprintf('%s/behavior.mat', data_info.behavior_dir);
save(save_file_name, 'behavior');

% Append Information to ParamSet
save_file_name = sprintf('%s/paramSet.mat', data_info.main_dir);
save(save_file_name, 'numTotalNeurons', 'numTotalLFPs', 'react_bounds', '-append');


