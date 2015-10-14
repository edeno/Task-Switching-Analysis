% This function queues up the code for computing the average predictive
% comparison between rules (at a specificied level of another covariate) on
% the cluster
function [apcJob] = computeAPC(regressionModel_str, timePeriod, type, varargin)

% Load Common Parameters
main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), 'session_names', 'validFolders');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, validFolders)) || strcmp(x, 'Testing'));
inParser.addRequired('type',  @ischar);
inParser.addParameter('numSim', 1000, @(x) isnumeric(x) && x > 0)
inParser.addParameter('numSamples', [], @(x) isnumeric(x))
inParser.addParameter('isWeighted', false, @islogical)
inParser.addParameter('isLocal', false, @islogical)
inParser.addParameter('overwrite', false, @islogical)
inParser.addParameter('session_names', [], @iscell)

inParser.parse(regressionModel_str, timePeriod, type, varargin{:});

% Add parameters to input structure after validation
apcParams = inParser.Results;
if ~isempty(apcParams.session_names),
    session_names = apcParams.session_names;
end
apcParams = rmfield(apcParams, 'session_names');
apcJob = [];

if apcParams.isLocal,
    % Run Locally
    for session_ind = 1:length(session_names),
        fprintf('\t...Session: %s\n', session_names{session_ind});
        apcJob{session_ind} = avrPredComp(session_names{session_ind}, apcParams);
    end
else
    % Use Cluster
    args = cellfun(@(x) {x; apcParams}', session_names, 'UniformOutput', false);
    apcJob = TorqueJob('avrPredComp', args, ...
        'walltime=24:00:00,mem=90GB');
end

end