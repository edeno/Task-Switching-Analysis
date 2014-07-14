function collectGAMpred(regressionModel_str, timePeriod, varargin)
%%
main_dir = '/data/home/edeno/Task Switching Analysis';
load(sprintf('%s/paramSet.mat', main_dir), ...
    'data_info', 'validFolders', 'session_names');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, validFolders)));
inParser.addParamValue('overwrite', false, @islogical)

inParser.parse(regressionModel_str, timePeriod, varargin{:});

% Add parameters to input structure after validation
params = inParser.Results;

% Specify Home and Data Directory
timePeriod_dir = sprintf('%s/%s', data_info.processed_dir, timePeriod);
data_dir = sprintf('%s/Models/%s', timePeriod_dir, params.regressionModel_str);

cd(data_dir);
GAMpred_names = strcat(session_names, '_GAMpred2.mat');
neurons_all = [];

fprintf('\nModel: %s\n', regressionModel_str);

for files_ind = 1:length(GAMpred_names),
    fprintf('\t...Session: %s\n', GAMpred_names{files_ind});
    file_name = sprintf('%s/%s', data_dir, GAMpred_names{files_ind});
    try
        load(file_name, 'neurons', 'gam', 'gamParams');
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

save_file_name = sprintf('%s/neurons2.mat', save_dir);
try
    saveMillerlab('edeno', save_file_name, 'neurons', ...
        'gam', 'gamParams', '-v7.3');
catch
end
end