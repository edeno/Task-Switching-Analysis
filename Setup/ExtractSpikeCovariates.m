%% Extract GLM Covariates
function [diaryLog] = ExtractSpikeCovariates(isLocal)
%% Setup
mainDir = getWorkingDir();
% Load Common Parameters
load(sprintf('%s/paramSet.mat', mainDir), 'sessionNames', 'numSessions', 'timePeriodNames', 'numSpikeLags', 'covInfo');
load(sprintf('%s/Behavior/behavior.mat', mainDir));
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
                numSpikeLags, ...
                covInfo, ...
                behavior{session_ind}, ...
                'overwrite', isOverwrite);
        end
    else
        % Use Cluster
        args = cellfun(@(session, beh) {session; ...
            timePeriodNames{timePeriod_ind}; ...
            numSpikeLags; ...
            covInfo; ...
            beh; ...
            'overwrite'; isOverwrite}', ...
            sessionNames, behavior, 'UniformOutput', false);
%         SpikeCovJob = TorqueJob('ExtractSpikeCovariatesBySession', args, ...
%             'walltime=0:30:00,mem=90GB');
        SpikeCovJob = SGEJob('ExtractSpikeCovariatesBySession', args, ...
            'h_rt=0:30:00,mem_total=94G');
        waitMatorqueJob(SpikeCovJob);
        [out, diaryLog{timePeriod_ind}] = gatherMatorqueOutput(SpikeCovJob); % Get the outputs
        for session_ind = 1:length(sessionNames),
            saveFileName = sprintf('%s/Processed Data/%s/SpikeCov/%s_SpikeCov.mat', mainDir, timePeriodNames{timePeriod_ind}, sessionNames{session_ind});

            SpikeCov = out{session_ind, 1};
            spikes = out{session_ind, 2};
            numNeurons = out{session_ind, 3};
            trialID = out{session_ind, 4};
            trialTime = out{session_ind, 5};
            percentTrials = out{session_ind, 6};
            wire_number = out{session_ind, 7};
            unit_number = out{session_ind, 8};
            neuronBrainArea = out{session_ind, 9};
            isCorrect = out{session_ind, 10};
            isAttempted = out{session_ind, 11};
            
            fprintf('\nSaving to %s....\n', saveFileName);
            saveDir = sprintf('%s/Processed Data/%s/SpikeCov/', mainDir, timePeriodNames{timePeriod_ind});
            if ~exist(saveDir, 'dir'),
                mkdir(saveDir);
            end
            
            save(saveFileName, 'SpikeCov', 'spikes', ...
                'numNeurons', 'trialID', 'trialTime', 'percentTrials', ...
                'wire_number', 'unit_number', 'neuronBrainArea', 'isCorrect', 'isAttempted', '-v7.3');
        end
    end
end
end