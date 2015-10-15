clear variables; clc;
ridgeLambda = 1;
smoothLambda = 10^(-3:3);
numFolds = 5;
isOverwrite = true;
timePeriods = {'Rule Response'};
model = {...
    's(Previous Error History Indicator, Trial Time) + s(Response Direction, Trial Time)', ...
    's(Previous Error History Indicator, Trial Time) + s(Response Direction, Trial Time) + s(Rule Repetition, Trial Time)', ...
    's(Previous Error History Indicator, Trial Time) + s(Response Direction, Trial Time) + s(Indicator Prep Time, Trial Time)', ...
    's(Previous Error History Indicator, Trial Time) + s(Response Direction, Trial Time) + s(Congruency History, Trial Time)', ...
    's(Previous Error History Indicator, Trial Time) + s(Response Direction, Trial Time) + s(Rule, Trial Time)', ...
    };

main_dir = getWorkingDir();

for time_ind = 1:length(timePeriods),
    
    fprintf('\n\t Time Period: %s\n', timePeriods{time_ind});
    timePeriod_dir = sprintf('%s/Processed Data/%s/', main_dir, timePeriods{time_ind});
    
    for model_ind = 1:length(model)
        %% Run the model
        gamJob = GAMcluster(model{model_ind}, timePeriods{time_ind}, ...
            'numFolds', numFolds, ...
            'overwrite', isOverwrite, ...
            'ridgeLambda', ridgeLambda, ...
            'smoothLambda', smoothLambda, ...
            'isPrediction', false, ...
            'isLocal', false);
        
        waitMatorqueJob(gamJob); % Wait for job to finish running
        [out, diaryLog] = gatherMatorqueOutput(gamJob); % Get the outputs
        
        %% Name the outputs
        neurons = [out{:,1}];
        stats = [out{:, 2}];
        gam = [out{:, 3}];
        designMatrix  = out(:, 4);
        modelList = [out{end, 5}];
        
        %% Create corresponding local directories
        modelDir = sprintf('%s/Models/', timePeriod_dir);
        
        if ~exist(modelDir, 'dir'),
            mkdir(modelDir);
        end
        saveDir = sprintf('%s/Models/%s/Collected GAMfit/', timePeriod_dir, modelList(model{model_ind}));
        if ~exist(saveDir, 'dir'),
            mkdir(saveDir);
        end
        
        %% Save to file
        fprintf('Saving GAMs ...\n');
        save(sprintf('%s/neurons.mat', saveDir), 'neurons', 'gam', '-v7.3');
        save(sprintf('%s/stats.mat', saveDir), 'stats', '-v7.3');
        save(sprintf('%s/log.mat', saveDir), 'diaryLog', '-v7.3');
        save(sprintf('%s/designMatrix.mat', saveDir), 'designMatrix', '-v7.3');
        
        clear neurons stats gam designMatrix
    end
    % Save model list
    save(sprintf('%s/Models/modelList.mat', timePeriod_dir), 'modelList');
end