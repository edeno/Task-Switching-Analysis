function collectAPCs(regressionModel_str, timePeriod, main_dir, covariate_type, varargin)

% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), 'session_names', 'data_info', 'validFolders');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, validFolders)));
inParser.addRequired('covariate_type',  @ischar);
inParser.addParamValue('overwrite', false, @islogical)

inParser.parse(regressionModel_str, timePeriod, covariate_type, varargin{:});

fprintf('\ntimePeriod:%s...\n\tmodel:%s...\n\t\tcovariate:%s...\n', timePeriod, regressionModel_str, covariate_type);

% Add parameters to input structure after validation
apcParams = inParser.Results;

data_dir = sprintf('%s/%s/Models/%s/APC/%s/', data_info.processed_dir, timePeriod, ...
    regressionModel_str, covariate_type);

save_dir = [data_dir, 'Collected'];
if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end

save_file_name = [save_dir, '/apc_collected.mat'];

if exist(save_file_name, 'file') && ~apcParams.overwrite,
    fprintf('\nFile already exists...\n');
    return;
end

apc_names = strcat(session_names, '_APC.mat');
avpred = [];

for session_ind = 1:length(apc_names),
    try
        cur_file = load([data_dir, apc_names{session_ind}]);
        avpred = [avpred cur_file.avpred];
    catch
        fprintf('\n%s does not exist\n', apc_names{session_ind});
        return;
    end 
end
fprintf('\n Saving... \n');
if ~isempty(avpred),
    saveMillerlab('edeno', save_file_name, 'avpred');
end


end