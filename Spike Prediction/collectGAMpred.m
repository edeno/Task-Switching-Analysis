function collectGAMfit(modelFolderName, timePeriod, varargin)
%%
main_dir = getenv('MAIN_DIR');
load(sprintf('%s/paramSet.mat', main_dir), ...
    'data_info', 'validFolders', 'session_names');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, validFolders)));
inParser.addParamValue('overwrite', false, @islogical)

inParser.parse(modelFolderName, timePeriod, varargin{:});

% Add parameters to input structure after validation
params = inParser.Results;

% Specify Home and Data Directory
timePeriod_dir = sprintf('%s/%s', data_info.processed_dir, timePeriod);
data_dir = sprintf('%s/Models/%s', timePeriod_dir, params.regressionModel_str);

cd(data_dir);
GAMpred_names = strcat(session_names, '_GAMpred.mat');
neurons_all = [];
numSim = 1000;

for files_ind = 1:length(GAMpred_names),
    
    try
        file_name = sprintf('%s/%s', data_dir, GAMpred_names{files_ind});
        load(file_name, 'neurons', 'gam', 'gamParams', 'numNeurons', 'validPredType');
        fprintf('\t...Session: %s\n', GAMpred_names{files_ind});
    catch
        continue;
    end
    
    neurons = rmfield(neurons, 'stats');
    neurons_all = [neurons_all neurons];
end

neurons = neurons_all;
%%
save_dir = sprintf('%s/GAMpred', data_dir);

if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end

save_file_name = sprintf('%s/neurons.mat', save_dir);

[~, hostname] = system('hostname');
hostname = strtrim(hostname);
try
    if strcmp(hostname, 'millerlab'),
        saveMillerlab('edeno', save_file_name, 'neurons', ...
            'gam', 'gamParams', 'validPredType', '-v7.3');
    else
        save(save_file_name, 'neurons', ...
            'gam', 'gamParams', 'validPredType', '-v7.3');
    end
catch
    fprintf('Model does not exist');
end

end