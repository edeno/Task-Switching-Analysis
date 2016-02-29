function GAMCluster_standalone(session_ind, regressionModel_str, timePeriod, varargin)
%#function ComputeGAMfit
%#function fitGAM
%#function gamModelMatrix
%#function gamStats
%#function getGLMDistrParams
%#function insertNaN
%#function modelFormulaParse
%#function spline_basis
%#function testlink

fprintf('\nMatlab\n')
fprintf('---------\n')
fprintf('Session_ind: %s\n', session_ind);
fprintf('Model: %s\n', regressionModel_str);
fprintf('Time Period: %s\n', timePeriod);
fprintf('vargain: %s\n', varargin{:});
fprintf('---------\n');

% Numbers are passed as strings. Need to convert to correct type
session_ind = str2double(session_ind);
if ~isempty(varargin),
    convert_ind = 2:2:length(varargin);
    % Don't convert predType -- which is entered as a string
    predTypeArg_ind = find(ismember(varargin, 'predType')) + 1; % Find predType argument if it exists
    convert_ind = convert_ind(~ismember(convert_ind, predTypeArg_ind)); % Remove from index of cells to convert
    varargin(convert_ind) = deal(cellfun(@(x) str2num(x), varargin(convert_ind), 'UniformOutput', false));
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
inParser.addParameter('numFolds', 5, @(x) isnumeric(x) && x > 0)
inParser.addParameter('predType', 'Dev', @(x) any(ismember(x, validPredType)))
inParser.addParameter('smoothLambda', 10.^(-3:4), @isvector)
inParser.addParameter('ridgeLambda', 1, @isvector)
inParser.addParameter('overwrite', true, @isnumeric)
inParser.addParameter('includeIncorrect', false, @isnumeric);
inParser.addParameter('includeFixationBreaks', false, @isnumeric);
inParser.addParameter('includeTimeBeforeZero', true, @isnumeric);
inParser.addParameter('isPrediction', false, @isnumeric);
inParser.addParameter('isLocal', false, @isnumeric);
inParser.addParameter('numCores', 9, @(x) isnumeric(x) && x > 0);

inParser.parse(regressionModel_str, timePeriod, varargin{:});

% Add parameters to input structure after validation
gamParams = inParser.Results;
ComputeGAMfit(sessionNames{session_ind}, gamParams, covInfo);

exit;
end