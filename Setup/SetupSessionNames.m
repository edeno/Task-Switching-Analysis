%% Setup Session Names
clear all; close all; clc;
main_dir = getenv('MAIN_DIR');
load_file_name = sprintf('%s/paramSet.mat', main_dir);
load(load_file_name);

cd(data_info.rawData_dir)
files = dir('*.sdt');
session_names = cellfun(@(x) regexprep(x, '.sdt', ''), {files.name}, 'UniformOutput', false);
numSessions = length(session_names);

%% Append Information to paramSet
save(load_file_name, 'session_names', 'numSessions', '-append');