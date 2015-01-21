%% Convert Raster to JSON
clear all; close all; clc;

%% Setup
main_dir = '/data/home/edeno/Task Switching Analysis';
cd(main_dir);

% Find Cluster
jobMan = parcluster();

% Load Common Parameters
load('paramSet.mat', 'session_names', 'data_info', 'numSessions');

%% Set Parameters
% Overwrite?
isOverwrite = true;

save_dir = sprintf('%s/Entire Trial/Visualization Data/', data_info.figure_dir);

if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end

%% Process Data
rasterJob = cell(1, length(session_names));

% Loop through files in the data directory
for session_ind = 1:length(session_names),
    
    if exist(sprintf('%s/%s.json', save_dir, session_names{session_ind}), 'file') && ~isOverwrite,
       continue;
    end
    
    fprintf('\t...Session: %s\n', session_names{session_ind});
    rasterJob{session_ind} = createCommunicatingJob(jobMan, 'AdditionalPaths', {data_info.script_dir}, 'AttachedFiles', ...
        {which('saveMillerlab')}, 'NumWorkersRange', [12 12], 'Type', 'Pool');
    
    createTask(rasterJob{session_ind}, @convertFile_toJSON, 0, {session_names{session_ind}, save_dir});
    submit(rasterJob{session_ind}); 
end