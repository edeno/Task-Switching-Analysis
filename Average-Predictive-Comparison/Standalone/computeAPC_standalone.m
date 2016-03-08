function computeAPC_standalone(session_ind, regressionModel_str, timePeriod, factorOfInterest, varargin)
%#function apc_weights
%#function modelFormulaParse
%#function getWorkingDir
%#function dummyvar
%#function createBSpline
%#function avrPredComp

fprintf('\nMatlab\n')
fprintf('---------\n')
fprintf('Session_ind: %s\n', session_ind);
fprintf('Model: %s\n', regressionModel_str);
fprintf('Time Period: %s\n', timePeriod);
fprintf('Factor Of Interest: %s\n', factorOfInterest);
fprintf('vargain: %s\n', varargin{:});
fprintf('---------\n');

% Numbers are passed as strings. Need to convert to correct type
session_ind = str2double(session_ind);
if ~isempty(varargin),
    convert_ind = 2:2:length(varargin);
    varargin(convert_ind) = deal(cellfun(@(x) str2num(x), varargin(convert_ind), 'UniformOutput', false));
end
%% Validate Parameters
main_dir = getWorkingDir();

% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), ...
    'timePeriodNames', 'sessionNames', 'covInfo');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, timePeriodNames)) || strcmp(x, 'Testing'));
inParser.addRequired('factorOfInterest',  @(x) ischar(x) && covInfo.isKey(x));
inParser.addParameter('numSim', 1000, @(x) isnumeric(x) && x > 0)
inParser.addParameter('numSamples', [], @(x) isnumeric(x))
inParser.addParameter('isWeighted', false, @isnumeric)
inParser.addParameter('overwrite', false, @isnumeric)
inParser.addParameter('sessionNames', [], @iscell)
inParser.addParameter('numCores', 12, @(x) isnumeric(x) && x > 0);

inParser.parse(regressionModel_str, timePeriod, factorOfInterest, varargin{:});

% Add parameters to input structure after validation
apcParams = inParser.Results;
if ~isempty(apcParams.sessionNames),
    sessionNames = apcParams.sessionNames;
end
apcParams = rmfield(apcParams, 'sessionNames');

myCluster = parcluster('local');
if getenv('ENVIRONMENT')    % true if this is a batch job
    myCluster.JobStorageLocation = getenv('TMPDIR');  % points to TMPDIR
end

parpool(myCluster, apcParams.numCores);
avrPredComp(sessionNames{session_ind}, apcParams, covInfo);

exit;
end
