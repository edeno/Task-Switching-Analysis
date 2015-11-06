function GAMCluster_standalone(session_ind, regressionModel_str, timePeriod, varargin)
% Standalone Main Program Rules
% a) It must be a function, and it must not have output
%    >> myStandalone 2000 4       % command  syntax
%    >> myStandalone(2000, 4)     % function syntax
% b) The standalone runs in command syntax only
%    scc1$ ./myExecR2013a 2000 4
% c) Commandline input (if any) are passed as strings

% Specify number of processors
NPROCS = 12;
% Must be converted to double for used as double
session_ind = str2double(session_ind);
if ~isempty(varargin),
    varargin{2:2:end} = str2double(varargin{2:2:end});
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
inParser.addParamValue('overwrite', false, @isnumeric)
inParser.addParamValue('includeIncorrect', false, @isnumeric);
inParser.addParamValue('includeFixationBreaks', false, @isnumeric);
inParser.addParamValue('includeTimeBeforeZero', true, @isnumeric);
inParser.addParamValue('isPrediction', false, @isnumeric);

inParser.parse(regressionModel_str, timePeriod, varargin{:});

% Add parameters to input structure after validation
gamParams = inParser.Results;

% Compute sum with Parallel Computing Toolbox's parfor
matlabpool('local', NPROCS);  % R2013a or older
ComputeGAMfit(sessionNames{session_ind}, gamParams, covInfo);
matlabpool close;
exit;

end