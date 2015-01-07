% Aggregate Average Predictive Comparisons into one file per comparison
clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
overwrite = true;
load([main_dir, '/paramSet.mat'], 'validFolders', 'data_info');

timePeriod = validFolders;
numTimePeriods = length(validFolders);

type_ind = 1;
jobMan = parcluster();

% Loop over different time periods in the trial
for time_ind = 1:numTimePeriods,
    
    models_dir = [main_dir, '/Processed Data/', timePeriod{time_ind}, '/Models/'];
    model = dir(models_dir);
    model = {model.name};
    model(ismember(model, {'.', '..'})) = [];
    numModels = length(model);
    
    % Loop over fitted models
    for model_ind = 1:numModels,
        
        apc_dir = [models_dir, model{model_ind}, '/APC/'];
        
        covariate_type = dir(apc_dir);
        covariate_type = {covariate_type.name};
        covariate_type(ismember(covariate_type, {'.', '..'})) = [];
        
        % Loop over the average predictive comparison fits and collect them
        % into one file
        for cov_ind = 1:length(covariate_type),
            apcJob{type_ind} = createCommunicatingJob(jobMan, 'AdditionalPaths', {data_info.script_dir}, 'AttachedFiles', ...
                {which('saveMillerlab')}, 'NumWorkersRange', [12 12], 'Type', 'Pool');
            
            createTask(apcJob{type_ind}, @collectAPCs, 0, ...
                {model{model_ind}, timePeriod{time_ind}, main_dir, covariate_type{cov_ind}, 'overwrite', overwrite});
            submit(apcJob{type_ind});
            
            type_ind = type_ind + 1;
        end
    end
end