function [] = computePermutationAnalysis_standalone(session_ind, covariateOfInterest, timePeriod, varargin)
%#function getWorkingDir
%#function firingRatePermutationAnalysis

fprintf('\nMatlab\n')
fprintf('---------\n')
fprintf('Session_ind: %s\n', session_ind);
fprintf('Time Period: %s\n', timePeriod);
fprintf('Covariate Of Interest: %s\n', covariateOfInterest);
fprintf('vargain: %s\n', varargin{:});
fprintf('---------\n');

% Numbers are passed as strings. Need to convert to correct type
session_ind = str2double(session_ind);
if ~isempty(varargin),
    convert_ind = 2:2:length(varargin);
    varargin(convert_ind) = deal(cellfun(@(x) str2num(x), varargin(convert_ind), 'UniformOutput', false));
end

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
inParser.addParameter('walltime', '2:00:00', @ischar);
inParser.addParameter('mem', '24GB', @ischar);
inParser.addParameter('numCores', 12, @(x) isnumeric(x) && x > 0);

inParser.parse(covariateOfInterest, timePeriod, varargin{:});

% Add parameters to input structure after validation
permutationParams = inParser.Results;

myCluster = parcluster('local');
if getenv('ENVIRONMENT')    % true if this is a batch job
    myCluster.JobStorageLocation = getenv('TMPDIR');  % points to TMPDIR
end

parpool(myCluster, permutationParams.numCores);
firingRatePermutationAnalysis(sessionNames{session_ind}, permutationParams, covInfo);
exit;
end
