%% Extract GLM Covariates
clear variables; clc;
%% Setup
main_dir = getWorkingDir();
% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), 'session_names', 'numSessions', 'validFolders', 'numMaxLags');
%% Set Parameters
% Overwrite?
isOverwrite = true;
isLocal = true;
%% Loop through Time Periods to Extract Spikes
for folder_ind = 1:length(validFolders),
    
    fprintf('\nProcessing time period: %s ...\n', validFolders{folder_ind});
    if isLocal,
        % Run Locally
        for session_ind = 1:length(session_names),
            SetupGLMCov_cluster(session_names{session_ind}, validFolders{folder_ind}, numMaxLags, 'overwrite', isOverwrite);
        end
    else
        % Use Cluster
        args = cellfun(@(x) {x;  validFolders{folder_ind}; numMaxLags; 'overwrite'; isOverwrite}', session_names, 'UniformOutput', false);
        glmCovJob{folder_ind} = TorqueJob('SetupGLMCov_cluster', args, ...
            'walltime=1:00:00,mem=16GB');
    end
    
end