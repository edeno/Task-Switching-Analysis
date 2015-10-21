%% Extract GLM Covariates
function [diaryLog] = ExtractSpikeCovariates(isLocal)
%% Setup
main_dir = getWorkingDir();
% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), 'sessionNames', 'numSessions', 'timePeriodNames', 'numMaxLags', 'covInfo');
load(sprintf('%s/Behavior/behavior.mat', main_dir));
%% Set Parameters
% Overwrite?
isOverwrite = true;
fprintf('\nExtracting Spike Covariates\n');
diaryLog = cell(1, length(timePeriodNames));
%% Loop through Time Periods to Extract Spikes
for timePeriod_ind = 1:length(timePeriodNames),
    fprintf('\nProcessing time period: %s ...\n', timePeriodNames{timePeriod_ind});
    if isLocal,
        % Run Locally
        for session_ind = 1:length(sessionNames),
            ExtractSpikeCovariatesBySession(sessionNames{session_ind}, ...
                timePeriodNames{timePeriod_ind}, ...
                numMaxLags, ...
                covInfo, ...
                behavior, ...
                'overwrite', isOverwrite);
        end
    else
        % Use Cluster
        args = cellfun(@(x) {x; ...
            timePeriodNames{timePeriod_ind}; ...
            numMaxLags; ...
            covInfo; ...
            behavior; ...
            'overwrite'; isOverwrite}', ...
            sessionNames, 'UniformOutput', false);
        SpikeCovJob = TorqueJob('ExtractSpikeCovariatesBySession', args, ...
            'walltime=0:30:00,mem=90GB');
        waitMatorqueJob(SpikeCovJob);
        [out, diaryLog{timePeriod_ind}] = gatherMatorqueOutput(SpikeCovJob); % Get the outputs
        for session_ind = 1:length(sessionNames),
            save_file_name = sprintf('%s/Processed Data/%s/SpikeCov/%s_SpikeCov.mat', main_dir, timePeriodNames{timePeriod_ind}, sessionNames{session_ind});

            SpikeCov = out{session_ind, 1};
            spikes = out{session_ind, 2};
            sample_on = out{session_ind, 3};
            numNeurons = out{session_ind, 4};
            trial_id = out{session_ind, 5};
            trial_time = out{session_ind, 6};
            percent_trials = out{session_ind, 7};
            wire_number = out{session_ind, 8};
            unit_number = out{session_ind, 9};
            pfc = out{session_ind, 10};
            isCorrect = out{session_ind, 11};
            isAttempted = out{session_ind, 12};
            
            fprintf('\nSaving to %s....\n', save_file_name);
            save_dir = sprintf('%s/Processed Data/%s/SpikeCov/', main_dir, timePeriodNames{timePeriod_ind});
            if ~exist(save_dir, 'dir'),
                mkdir(save_dir);
            end
            
            save(save_file_name, 'SpikeCov', 'spikes', 'sample_on', ...
                'numNeurons', 'trial_id', 'trial_time', 'percent_trials', ...
                'wire_number', 'unit_number', 'pfc', 'isCorrect', 'isAttempted', '-v7.3');
        end
    end
end
end