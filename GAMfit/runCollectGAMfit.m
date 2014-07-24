%% Collects GAMfit session files into one file
clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
load(sprintf('%s/paramSet.mat', main_dir), 'data_info', 'validFolders');

for time_ind = 1:length(validFolders),
    fprintf('\nTime Period: %s\n', validFolders{time_ind});
    models_dir = sprintf('%s/%s/Models', data_info.processed_dir, validFolders{time_ind});
    
    models = dir(models_dir);
    models = {models.name};
    models = models(~ismember(models, {'.', '..'}));
    
    for models_ind = 1:length(models),
        fprintf('\tModel: %s\n', models{models_ind});
        collectGAMfit(models{models_ind}, validFolders{time_ind});
    end
end