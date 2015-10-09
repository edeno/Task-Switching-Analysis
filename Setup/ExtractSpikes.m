function ExtractSpikes(isLocal)
%% Setup
main_dir = getWorkingDir();

% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), 'session_names', 'data_info', 'trial_info', ...
    'numSessions', 'validFolders', 'encodeMap');

% Set parameters
spike_opts.end_off = 0;
spike_opts.win_step = 0;
spike_opts.smooth_param = [];
spike_opts.smooth_type = [];
spike_opts.time_resample = [];
%% Loop through Time Periods to Extract Spikes
for folder_ind = 1:length(validFolders),
    fprintf('\n\nProcessing Spikes for: %s\n', validFolders{folder_ind});
    if any(ismember(validFolders{folder_ind}, {'Entire Trial', 'Intertrial Interval', 'Fixation'})),
        spike_opts.start_off = 0;
    else
        spike_opts.start_off = -175;
    end
    
    if isLocal,
        % Run Locally
        for session_ind = 1:length(session_names),
            SetupSpikes_cluster(session_names{session_ind}, ...
                encodeMap(validFolders{folder_ind}), ...
                spike_opts, ...
                validFolders{folder_ind});
        end
    else
        % Use Cluster
        args = cellfun(@(x) {x; ...
            encodeMap(validFolders{folder_ind}); ...
            spike_opts; validFolders{folder_ind}}', ...
            session_names, 'UniformOutput', false);
        spikeJob{folder_ind} = TorqueJob('SetupSpikes_cluster', args, ...
            'walltime=1:00:00,mem=16GB');
        waitMatorqueJob(spikeJob{folder_ind});
    end
end
%% Append Information to ParamSet
save_file_name = sprintf('%s/paramSet.mat', main_dir);
save(save_file_name, 'spike_opts', '-append');
end