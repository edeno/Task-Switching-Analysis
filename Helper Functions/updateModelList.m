function updateModelList(gamParams)
%% Get directories
main_dir = getWorkingDir();
timePeriod_dir = sprintf('%s/Processed Data/%s/', main_dir, gamParams.timePeriod);
%% Create Model Directory
model_dir = sprintf('%s/Models/', timePeriod_dir);

if ~exist(model_dir, 'dir'),
    mkdir(model_dir);
end

if exist(sprintf('%s/Models/modelList.mat', timePeriod_dir), 'file'),
    load(sprintf('%s/Models/modelList.mat', timePeriod_dir), 'modelList');
    if ~modelList.isKey(gamParams.regressionModel_str)
        modelList(gamParams.regressionModel_str) = sprintf('M%d', modelList.length + 1);
    end
else
    modelList = containers.Map(gamParams.regressionModel_str, 'M1');
end
save(sprintf('%s/Models/modelList.mat', timePeriod_dir), 'modelList');

save_dir = sprintf('%s/Models/%s', timePeriod_dir, modelList(gamParams.regressionModel_str));

if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end
end