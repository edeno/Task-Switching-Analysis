clear all; close all; clc;

%% Setup
main_dir = '/data/home/edeno/Task Switching Analysis';
cd(main_dir);

% Find Cluster
jobMan = parcluster();
cleanupClusterJob(jobMan, 'edeno', 'finished');

% Load Common Parameters
load('paramSet.mat', 'session_names', 'data_info', 'trial_info', 'numSessions');

% Set parameters
spike_opts.start_off = -175;
spike_opts.end_off = 0;
spike_opts.win_step = 0;
spike_opts.smooth_param = [];
spike_opts.smooth_type = [];
spike_opts.time_resample = [];
spike_opts.data_dir = data_info.rawData_dir;

encode_period = [trial_info.Start_encode trial_info.FixationOn_encode; ...
    trial_info.FixationAccquired_encode trial_info.RuleOn_encode; ...
    trial_info.RuleOn_encode trial_info.SampleOn_encode; ...
    trial_info.SampleOn_encode trial_info.SaccadeStart_encode; ...
    trial_info.RuleOn_encode trial_info.SaccadeStart_encode; ...
    trial_info.SaccadeStart_encode trial_info.SaccadeFixation_encode; ...
    trial_info.SaccadeFixation_encode trial_info.End_encode];

validFolders = {'Intertrial Interval', 'Fixation', 'Rule Stimulus', 'Stimulus Response', 'Rule Response', 'Saccade', 'Reward'};

%% Loop through Time Periods to Extract Spikes

for folder_ind = 1:length(validFolders),
    
    encode = encode_period(folder_ind, :);
    save_dir = sprintf('%s/%s', data_info.processed_dir, validFolders{folder_ind});
    figure_dir = sprintf('%s/%s', data_info.figure_dir, validFolders{folder_ind});
    
    if ~exist(save_dir, 'dir'),
        mkdir(save_dir);
        mkdir(figure_dir);
    end
    
    % Create a job to run on the cluster
    spikesJob = createJob(jobMan, 'AdditionalPaths', {data_info.script_dir}, 'AttachedFiles', {which('saveMillerlab')}, 'NumWorkersRange', [1 12]);
    
    % Loop through Raw Data Directories
    for session_ind = 1:numSessions,
        
        createTask(spikesJob, @SetupSpikes_cluster, 0, ...
            {session_names{session_ind}, encode, spike_opts, save_dir});
        
    end  % End Raw Data Directories
    
    submit(spikesJob);
    
end

%% Append Information to ParamSet
save_file_name = sprintf('%s/paramSet.mat', data_info.main_dir);
save(save_file_name, 'spike_opts', 'validFolders', '-append');