function GAMCluster_standalone(session_ind, regressionModel_str, timePeriod, varargin)
fprintf('\nMatlab\n')
fprintf('---------\n')
fprintf('Session_ind: %s\n', session_ind);
fprintf('Model: %s\n', regressionModel_str);
fprintf('Time Period: %s\n', timePeriod);
fprintf('vargain: %s\n', varargin{:});
fprintf('---------\n');

% Specify number of processors
NPROCS = 12;
% Numbers are passed as strings. Need to convert to correct type
session_ind = str2double(session_ind);
if ~isempty(varargin),
    convert_ind = 2:2:length(varargin);
    % Don't convert predType -- which is entered as a string
    convert_ind = convert_ind(~ismember(convert_ind, (find(ismember(varargin, 'predType')) + 1)));
    varargin(convert_ind) = deal(cellfun(@(x) str2double(x), varargin(convert_ind), 'UniformOutput', false));
end
%% Validate Parameters
main_dir = getWorkingDir();

% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), ...
    'covInfo', 'timePeriodNames', 'sessionNames', ...
    'monkeyNames', 'validPredType');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, timePeriodNames)));
inParser.addParamValue('numFolds', 5, @(x) isnumeric(x) && x > 0)
inParser.addParamValue('predType', 'Dev', @(x) any(ismember(x, validPredType)))
inParser.addParamValue('smoothLambda', 10.^(-3:4), @isvector)
inParser.addParamValue('ridgeLambda', 1, @isvector)
inParser.addParamValue('overwrite', true, @isnumeric)
inParser.addParamValue('includeIncorrect', false, @isnumeric);
inParser.addParamValue('includeFixationBreaks', false, @isnumeric);
inParser.addParamValue('includeTimeBeforeZero', true, @isnumeric);
inParser.addParamValue('isPrediction', false, @isnumeric);
inParser.addParamValue('isLocal', false, @isnumeric);

inParser.parse(regressionModel_str, timePeriod, varargin{:});

% Add parameters to input structure after validation
gamParams = inParser.Results;
myCluster = parcluster('local');
if getenv('ENVIRONMENT')    % true if this is a batch job
    myCluster.JobStorageLocation = getenv('TMPDIR');  % points to TMPDIR
end

% Compute sum with Parallel Computing Toolbox's parfor
if verLessThan('matlab', '8.2'),
    matlabpool(myCluster, NPROCS);  % R2013a or older
    ComputeGAMfit(sessionNames{session_ind}, gamParams, covInfo);
    matlabpool close;
else
    parpool(myCluster, NPROCS);
    ComputeGAMfit(sessionNames{session_ind}, gamParams, covInfo);
end

exit;
end