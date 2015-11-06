% This function queues up the code for computing the average predictive
% comparison between rules (at a specificied level of another covariate) on
% the cluster
function [apcJob] = computeAPC(regressionModel_str, timePeriod, factorOfInterest, varargin)

% Load Common Parameters
main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), 'sessionNames', 'timePeriodNames', 'covInfo');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, timePeriodNames)) || strcmp(x, 'Testing'));
inParser.addRequired('factorOfInterest',  @ischar);
inParser.addParameter('numSim', 1000, @(x) isnumeric(x) && x > 0)
inParser.addParameter('numSamples', [], @(x) isnumeric(x))
inParser.addParameter('isWeighted', false, @islogical)
inParser.addParameter('isLocal', false, @islogical)
inParser.addParameter('overwrite', false, @islogical)
inParser.addParameter('sessionNames', [], @iscell)

inParser.parse(regressionModel_str, timePeriod, factorOfInterest, varargin{:});

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
        apcJob{session_ind} = avrPredComp(sessionNames{session_ind}, apcParams, covInfo);
    end
else
    % Use Cluster
    args = cellfun(@(x) {x; apcParams; covInfo}', sessionNames, 'UniformOutput', false);
    apcJob = TorqueJob('avrPredComp', args, ...
        'walltime=24:00:00,mem=108GB');
end

end