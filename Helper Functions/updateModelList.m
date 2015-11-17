function updateModelList(gamParams)
%% Get directories
main_dir = getWorkingDir();
timePeriod_dir = sprintf('%s/Processed Data/%s/', main_dir, gamParams.timePeriod);
%% Create Model Directory
model_dir = sprintf('%s/Models/', timePeriod_dir);

if ~exist(model_dir, 'dir'),
    fprintf('\nCreating model directory: %s\n', model_dir);
    mkdir(model_dir);
end

if exist(sprintf('%s/Models/modelList.mat', timePeriod_dir), 'file'),
    load(sprintf('%s/Models/modelList.mat', timePeriod_dir), 'modelList');
    if ~modelList.isKey(gamParams.regressionModel_str)
        fprintf('Adding model %s to list...\n', gamParams.regressionModel_str);
        fprintf('Folder name: %s\n', sprintf('M%d', modelList.length + 1));
        modelList(gamParams.regressionModel_str) = sprintf('M%d', modelList.length + 1);
    end
else
    fprintf('Adding model %s to list...\n', gamParams.regressionModel_str);
    fprintf('Folder name: M1\n');
    modelList = containers.Map(gamParams.regressionModel_str, 'M1');
end
save(sprintf('%s/Models/modelList.mat', timePeriod_dir), 'modelList');

save_dir = sprintf('%s/Models/%s', timePeriod_dir, modelList(gamParams.regressionModel_str));

if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end
end