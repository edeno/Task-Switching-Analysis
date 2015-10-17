%% Extract GLM Covariates
function [diaryLog] = ExtractGLMCov(isLocal)
%% Setup
main_dir = getWorkingDir();
% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), 'session_names', 'numSessions', 'validFolders', 'numMaxLags', 'cov_info');
load(sprintf('%s/Behavior/behavior.mat', main_dir));
%% Set Parameters
% Overwrite?
isOverwrite = true;
fprintf('\nExtracting GAM Covariates\n');
glmCovJob = cell(1, length(validFolders));
diaryLog = cell(1, length(validFolders));
%% Loop through Time Periods to Extract Spikes
for folder_ind = 1:length(validFolders),
    fprintf('\nProcessing time period: %s ...\n', validFolders{folder_ind});
    if isLocal,
        % Run Locally
        for session_ind = 1:length(session_names),
            SetupGLMCov_cluster(session_names{session_ind}, ...
                validFolders{folder_ind}, ...
                numMaxLags, ...
                cov_info, ...
                behavior, ...
                'overwrite', isOverwrite);
        end
    else
        % Use Cluster
        args = cellfun(@(x) {x; ...
            validFolders{folder_ind}; ...
            numMaxLags; ...
            cov_info; ...
            behavior; ...
            'overwrite'; isOverwrite}', ...
            session_names, 'UniformOutput', false);
        glmCovJob{folder_ind} = TorqueJob('SetupGLMCov_cluster', args, ...
            'walltime=0:30:00,mem=90GB');
        waitMatorqueJob(glmCovJob{folder_ind});
        [out, diaryLog{folder_ind}] = gatherMatorqueOutput(glmCovJob{folder_ind}); % Get the outputs
        for session_ind = 1:length(session_names),
            save_file_name = sprintf('%s/Processed Data/%s/GLMCov/%s_GLMCov.mat', main_dir, validFolders{folder_ind}, session_names{session_ind});

            GLMCov = out{session_ind, 1};
            spikes = out{session_ind, 1};
            sample_on = out{session_ind, 1};
            numNeurons = out{session_ind, 1};
            trial_id = out{session_ind, 1};
            trial_time = out{session_ind, 1};
            percent_trials = out{session_ind, 1};
            wire_number = out{session_ind, 1};
            unit_number = out{session_ind, 1};
            pfc = out{session_ind, 1};
            isCorrect = out{session_ind, 1};
            isAttempted = out{session_ind, 1};
            
            fprintf('\nSaving to %s....\n', save_file_name);
            save_dir = sprintf('%s/Processed Data/%s/GLMCov', main_dir, validFolders{folder_ind});
            if ~exist(save_dir, 'dir'),
                mkdir(save_dir);
            end
            
            save(save_file_name, 'GLMCov', 'spikes', 'sample_on', ...
                'numNeurons', 'trial_id', 'trial_time', 'percent_trials', ...
                'wire_number', 'unit_number', 'pfc', 'isCorrect', 'isAttempted', '-v7.3');
             clear('GLMCov', 'spikes', 'sample_on', ...
                'numNeurons', 'trial_id', 'trial_time', 'percent_trials', ...
                'wire_number', 'unit_number', 'pfc', 'isCorrect', 'isAttempted', 'out');
        end
    end
end
end