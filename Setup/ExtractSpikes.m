clear variables; clc;

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

isLocal = true;

%% Loop through Time Periods to Extract Spikes
for folder_ind = 1:length(validFolders),
    
    if any(ismember(validFolders{folder_ind}, {'Entire Trial', 'Intertrial Interval', 'Fixation'})),
        spike_opts.start_off = 0;
    else
        spike_opts.start_off = -175;
    end
    end
end

%% Append Information to ParamSet
save_file_name = sprintf('%s/paramSet.mat', data_info.main_dir);
save(save_file_name, 'spike_opts', '-append');
