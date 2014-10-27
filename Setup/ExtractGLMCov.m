%% Extract GLM Covariates
clear all; close all; clc;

%% Setup
main_dir = '/data/home/edeno/Task Switching Analysis';
cd(main_dir);

% Find Cluster
jobMan = parcluster();
% cleanupClusterJob(jobMan, 'edeno', 'finished');

% Load Common Parameters
load('paramSet.mat', 'session_names', 'data_info', 'numSessions', 'validFolders');

%% Set Parameters
% Overwrite?
isOverwrite = true;
% Set Number of History Dependent Lags
numMaxLags = 20; % Spiking history lags

%% Loop through Time Periods to Extract Spikes

for folder_ind = 1:length(validFolders),
    
    fprintf('\nProcessing time period: %s ...\n', validFolders{folder_ind});
    save_dir = sprintf('%s/%s/GLMCov', data_info.processed_dir, validFolders{folder_ind});
    if ~exist(save_dir, 'dir'),
        mkdir(save_dir);
    end
    
    % Create a job to run on the cluster
    glmCovJob = createJob(jobMan, 'AdditionalPaths', {data_info.script_dir}, 'AttachedFiles', {which('saveMillerlab')}, 'NumWorkersRange', [1 12]);
    
    % Loop through Processed Data Directories
    for session_ind = 1:numSessions,
        
        createTask(glmCovJob, @SetupGLMCov_cluster, 0, ...
            {session_names{session_ind}, validFolders{folder_ind}, main_dir, numMaxLags, 'overwrite', isOverwrite});
        
    end  % End Processed Data Directories Loop
    
    submit(glmCovJob);
%     wait(glmCovJob);
end

%% Append Information to ParamSet
save_file_name = sprintf('%s/paramSet.mat', data_info.main_dir);
save(save_file_name, 'numMaxLags', '-append');