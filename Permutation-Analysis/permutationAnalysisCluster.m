function [permJob] = permutationAnalysisCluster(covariateOfInterest, timePeriod, varargin)

%% Validate Parameters
mainDir = getWorkingDir();

load(sprintf('%s/paramSet.mat', mainDir), ...
    'covInfo', 'timePeriodNames', 'sessionNames');

inParser = inputParser;
inParser.addRequired('covariateOfInterest', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, timePeriodNames)));
inParser.addParameter('overwrite', false, @islogical)
inParser.addParameter('includeIncorrect', false, @islogical);
inParser.addParameter('includeFixationBreaks', false, @islogical);
inParser.addParameter('includeTimeBeforeZero', false, @islogical);
inParser.addParameter('numRand', 10000, @(x) isnumeric(x));
inParser.addParameter('isLocal', false, @islogical);
inParser.addParameter('walltime', '2:00:00', @ischar);
inParser.addParameter('mem', '24GB', @ischar);
inParser.addParameter('numCores', 12, @(x) isnumeric(x) && x > 0);

inParser.parse(covariateOfInterest, timePeriod, varargin{:});

% Add parameters to input structure after validation
permutationParams = inParser.Results;
%% Process Data
fprintf('\nProcessing Covariate: %s\n', covariateOfInterest);
permJob = [];

if permutationParams.isLocal,
    % Run Locally
    for session_ind = 1:length(sessionNames),
        fprintf('\t...Session: %s\n', sessionNames{session_ind});
        firingRatePermutationAnalysis(sessionNames{session_ind}, permutationParams, covInfo);
    end
else
    % Use Cluster
    fprintf('Fitting model....\n');
    args = cellfun(@(x) {x; permutationParams; covInfo}', sessionNames, 'UniformOutput', false);
    permJob = TorqueJob('firingRatePermutationAnalysis', args, ...
        sprintf('walltime=%s,mem=%s,nodes=1:ppn=12', permutationParams.walltime, permutationParams.mem), true, 'numOutputs', 0);
end

end