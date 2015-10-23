function ExtractSpikes(isLocal)
%% Setup
main_dir = getWorkingDir();

% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), 'sessionNames', ...
    'timePeriodNames', 'encodeMap');

% Set parameters
spike_opts.end_off = 0;
spike_opts.win_step = 0;
spike_opts.smooth_param = [];
spike_opts.smooth_type = [];
spike_opts.time_resample = [];
%% Loop through Time Periods to Extract Spikes
for timePeriod_ind = 1:length(timePeriodNames),
    fprintf('\n\nProcessing Spikes for: %s\n', timePeriodNames{timePeriod_ind});
    if any(ismember(timePeriodNames{timePeriod_ind}, {'Entire Trial', 'Intertrial Interval', 'Fixation'})),
        spike_opts.start_off = 0;
    else
        spike_opts.start_off = -175;
    end
    
    if isLocal,
        % Run Locally
        for session_ind = 1:length(sessionNames),
            ExtractSpikesBySession(sessionNames{session_ind}, ...
                encodeMap(timePeriodNames{timePeriod_ind}), ...
                spike_opts, ...
                timePeriodNames{timePeriod_ind});
        end
    else
        % Use Cluster
        args = cellfun(@(x) {x; ...
            encodeMap(timePeriodNames{timePeriod_ind}); ...
            spike_opts; timePeriodNames{timePeriod_ind}}', ...
            sessionNames, 'UniformOutput', false);
        spikeJob{timePeriod_ind} = TorqueJob('SetupSpikes_cluster', args, ...
            'walltime=1:00:00,mem=16GB');
        waitMatorqueJob(spikeJob{timePeriod_ind});
    end
end
%% Append Information to ParamSet
save_file_name = sprintf('%s/paramSet.mat', main_dir);
save(save_file_name, 'spike_opts', '-append');
end