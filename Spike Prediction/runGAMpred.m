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
            'isPrediction', true, ...
            'includeTimeBeforeZero', includeTimeBeforeZero, ...
            'isLocal', false);
        
        waitMatorqueJob(gamJob); % Wait for job to finish running
    end
    % Save model list
    fprintf('Saving model list...\n');
    save(sprintf('%s/Models/modelList.mat', timePeriod_dir), 'modelList');
end