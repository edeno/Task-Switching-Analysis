function SetupSpikes_cluster(session_name, encode, spike_opts, timePeriod)

%% Extract Cortex Data
% Find trials file that corresponds to extracted data
fprintf('\nProcessing file %s...\n', session_name);
main_dir = getWorkingDir();
session_file = sprintf('%s/Raw Data/%s.sdt', main_dir, session_name);

fprintf('\tLoading data...\n');
load('-mat', session_file, 'cells', 'trials');

wire_number = nan(length(cells), 1);
unit_number = nan(length(cells), 1);
file_str = cell(length(cells), 1);
animal = cell(length(cells), 1);

for i = 1:length(cells),
    wire_number(i) = cells(i).WireNumber;
    unit_number(i) = cells(i).UnitNumber;
    file_str{i} = session_name;
    animal{i} = upper(regexprep(session_name, '\d+', ''));
end

[data, time, eye_pos, opts] = ExtractTimePeriod_Cortex(cells, trials, ...
    'StartEncode', encode(1), 'StartOffset', spike_opts.start_off, ...
    'EndEncode', encode(2), 'EndOffset', spike_opts.end_off, ...
    'SmoothType', spike_opts.smooth_type, 'SmoothParam', spike_opts.smooth_param, 'TimeResample', spike_opts.time_resample);

save_file_name = sprintf('%s/Processed Data/%s/%s_data.mat', main_dir, timePeriod, session_name);

save(save_file_name, 'data', 'time', 'wire_number', 'unit_number', 'file_str', 'animal', 'eye_pos', 'opts');


end