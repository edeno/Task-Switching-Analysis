function collectGAMfit(regressionModel_str, timePeriod, varargin)
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
GAMfit_names = strcat(session_names, '_GAMfit.mat');
neurons_all = [];
numSim = 1000;

for files_ind = 1:length(GAMfit_names),
    
    try
        file_name = sprintf('%s/%s', data_dir, GAMfit_names{files_ind});
        load(file_name, 'neurons', 'gam', 'gamParams', 'numNeurons');
        fprintf('\t...Session: %s\n', GAMfit_names{files_ind});
    catch
        continue;
    end
    
    for neuron_ind = 1:numNeurons,
        neurons(neuron_ind).par_sim = mvnrnd(neurons(neuron_ind).par_est, neurons(neuron_ind).stats.covb, numSim);
    end
    neurons = rmfield(neurons, 'stats');
    neurons_all = [neurons_all neurons];
end

neurons = neurons_all;
%%
save_dir = sprintf('%s/GAMfit', data_dir);

if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end

save_file_name = sprintf('%s/neurons.mat', save_dir);

try
    saveMillerlab('edeno', save_file_name, 'neurons', ...
        'gam', 'gamParams', '-v7.3');
catch
    fprintf('Model does not exist');
end

end