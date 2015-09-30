clear all; close all; clc;

%% Setup
main_dir = getWorkingDir();
cd(main_dir);

% Find Cluster
jobMan = parcluster();
cleanupClusterJob(jobMan, 'edeno', 'finished');

% Load Common Parameters
load('paramSet.mat', 'session_names', 'data_info', 'trial_info', ...
    'numSessions', 'validFolders', 'encodeMap');

% Set parameters
spike_opts.end_off = 0;
spike_opts.win_step = 0;
spike_opts.smooth_param = [];
spike_opts.smooth_type = [];
spike_opts.time_resample = [];
spike_opts.data_dir = data_info.rawData_dir;

%% Loop through Time Periods to Extract Spikes

for folder_ind = 1:length(validFolders),
    
    fprintf('Processing Spikes for: %s\n', validFolders{folder_ind});
    
    if any(ismember(validFolders{folder_ind}, {'Entire Trial', 'Intertrial Interval', 'Fixation'})),
        spike_opts.start_off = 0;
    else
        spike_opts.start_off = -175;
    end
    
    encode = encode_period(folder_ind, :);
    save_dir = sprintf('%s/%s', data_info.processed_dir, validFolders{folder_ind});
    figure_dir = sprintf('%s/%s', data_info.figure_dir, validFolders{folder_ind});
    
    if ~exist(save_dir, 'dir'),
        mkdir(save_dir);
        mkdir(figure_dir);
    end
    
    % Create a job to run on the cluster
    spikesJob = createJob(jobMan, 'AdditionalPaths', {data_info.script_dir});
    
    % Loop through Raw Data Directories
    for session_ind = 1:numSessions,
        
        createTask(spikesJob, @SetupSpikes_cluster, 0, ...
            {session_names{session_ind}, encode, spike_opts, save_dir});
        
    end  % End Raw Data Directories
    
    submit(spikesJob);
    
end

%% Append Information to ParamSet
save_file_name = sprintf('%s/paramSet.mat', data_info.main_dir);
save(save_file_name, 'spike_opts', '-append');
