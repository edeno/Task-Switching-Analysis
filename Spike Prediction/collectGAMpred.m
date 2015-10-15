function collectGAMpred(timePeriod)

main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), ...
   'validFolders', 'session_names');

inParser = inputParser;
inParser.addRequired('timePeriod', @(x) any(ismember(x, validFolders)));
inParser.parse(timePeriod);

% Specify Time Period Directory and get list of models
timePeriod_dir = sprintf('%s/Processed Data/%s', main_dir, timePeriod);
try
    load(sprintf('%s/modelList.mat', timePeriod_dir), 'modelList');
catch
    error('Model List does not exist');
end
% Loop over models
parfor model_ind = 1:modelList.Count,
    modelDir = sprintf('%s/%s/', timePeriod_dir, modelList.values(model_ind));
    collectFiles(modelDir, session_names);
end

end
function collectFiles(modelDir, session_names)
neurons_all = [];
GAMfit_names = strcat(session_names, '_GAMpred.mat');

%% Loop through sessions
for files_ind = 1:length(GAMfit_names),
    try
        file_name = sprintf('%s/%s', modelDir, GAMfit_names{files_ind});
        load(file_name, 'neurons', 'gam', 'gamParams');
        fprintf('\t...Session: %s\n', GAMfit_names{files_ind});
    catch
        continue;
    end

    neurons_all = [neurons_all neurons];
end

neurons = neurons_all;

%% Save
save_dir = sprintf('%s/GAMpred', data_dir);

if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end

save_file_name = sprintf('%s/neurons.mat', save_dir);

try
    save(save_file_name, 'neurons', ...
        'gam', 'gamParams', '-v7.3');
catch
    fprintf('Model does not exist');
end

end