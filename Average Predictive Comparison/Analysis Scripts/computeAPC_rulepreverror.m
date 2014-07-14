function computeAPC_rulepreverror(regressionModel_str, timePeriod, main_dir, varargin)

% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), 'session_names', 'data_info', 'validFolders');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, validFolders)));
inParser.addParamValue('numSim', 1000, @(x) isnumeric(x) && x > 0)
inParser.addParamValue('numSamples', 1000, @(x) isnumeric(x) && x > 0)
inParser.addParamValue('overwrite', false, @islogical)

inParser.parse(regressionModel_str, timePeriod, varargin{:});

% Add parameters to input structure after validation
apcParams = inParser.Results;

apcJob = cell(1, length(session_names));

save_dir = sprintf('%s/%s/Models/%s/APC/RulePrevError/', data_info.processed_dir, timePeriod, regressionModel_str);
if ~exist(save_dir, 'dir'),
   mkdir(save_dir);
end

apc_names = strcat(session_names, '_APC.mat');

% Specify Cluster Profile
jobMan = parcluster();

% Loop through files in the data directory
for session_ind = 1:length(session_names),
    
    if exist(sprintf('%s/%s', save_dir, apc_names{session_ind}), 'file') && ~apcParams.overwrite,
       continue;
    end
    
    fprintf('\t...Session: %s\n', session_names{session_ind});
    apcJob{session_ind} = createCommunicatingJob(jobMan, 'AdditionalPaths', {data_info.script_dir}, 'AttachedFiles', ...
        {which('saveMillerlab')}, 'NumWorkersRange', [12 12], 'Type', 'Pool');
    
    createTask(apcJob{session_ind}, @avrPredComp_RulePrevError, 0, {session_names{session_ind}, ...
        timePeriod, regressionModel_str, apcParams.numSim, apcParams.numSamples, save_dir, main_dir});
    submit(apcJob{session_ind});
    
end

end