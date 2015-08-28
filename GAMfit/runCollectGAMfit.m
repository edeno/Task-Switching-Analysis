%% Collects GAMfit session files into one file
clear all; close all; clc;
setMainDir;
main_dir = getenv('MAIN_DIR');
load(sprintf('%s/paramSet.mat', main_dir), 'data_info', 'validFolders');
jobMan = parcluster();
isOverwrite = false;

for time_ind = 1:length(validFolders),
    fprintf('\nTime Period: %s\n', validFolders{time_ind});
    models_dir = sprintf('%s/%s/Models', data_info.processed_dir, validFolders{time_ind});
    
    models = dir(models_dir);
    models = {models([models.isdir]).name};
    models = models(~ismember(models, {'.', '..'}));
    
    for models_ind = 1:length(models),
        fprintf('\tModel: %s\n', models{models_ind});
        if ~strcmp(strtrim(hostname), 'cns-ws18'),
            gamJob{models_ind} = createCommunicatingJob(jobMan, 'AdditionalPaths', {data_info.script_dir}, 'AttachedFiles', ...
                {which('saveMillerlab')}, 'NumWorkersRange', [12 12], 'Type', 'Pool');
            createTask(gamJob{models_ind}, @collectGAMfit, 0, ...
                {models{models_ind}, validFolders{time_ind}, 'overwrite', isOverwrite});
            submit(gamJob{models_ind});
        else
            collectGAMfit(models{models_ind}, validFolders{time_ind}, 'overwrite', isOverwrite);
        end
        
    end
end