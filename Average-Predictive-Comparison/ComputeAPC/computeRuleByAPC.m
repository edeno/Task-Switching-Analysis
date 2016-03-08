% This function queues up the code for computing the average predictive
% comparison between rules (at a specificied level of another covariate) on
% the cluster
function [apcJob] = computeRuleByAPC(regressionModel_str, timePeriod, type, varargin)

% Load Common Parameters
main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), 'sessionNames', 'timePeriodNames', ...
    'covInfo');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, timePeriodNames)) || strcmp(x, 'Testing'));
inParser.addRequired('factorOfInterest',  @ischar);
inParser.addParamValue('numSim', 1000, @(x) isnumeric(x) && x > 0)
inParser.addParamValue('numSamples', [], @(x) isnumeric(x))
inParser.addParamValue('isWeighted', false, @islogical)
inParser.addParamValue('isLocal', false, @islogical)
inParser.addParamValue('overwrite', false, @islogical)
inParser.addParamValue('sessionNames', [], @iscell)

inParser.parse(regressionModel_str, timePeriod, type, varargin{:});

% Add parameters to input structure after validation
apcParams = inParser.Results;
if ~isempty(apcParams.sessionNames),
    sessionNames = apcParams.sessionNames;
end
apcParams = rmfield(apcParams, 'sessionNames');
apcJob = [];

if apcParams.isLocal,
    % Run Locally
    for session_ind = 1:length(sessionNames),
        fprintf('\t...Session: %s\n', sessionNames{session_ind});
        apcJob{session_ind} = avrPredComp_RuleBy(sessionNames{session_ind}, apcParams, covInfo);
    end
else
    % Use Cluster
    args = cellfun(@(x) {x; apcParams; covInfo}', sessionNames, 'UniformOutput', false);
    apcJob = TorqueJob('avrPredComp_RuleBy', args, ...
        'walltime=24:00:00,mem=90GB');
end

end