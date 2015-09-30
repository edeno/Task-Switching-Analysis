% GAMcluster(regressionModel_str, timePeriod, timeType, varargin)
%
% valid covariates: 'Constant', 'Prep Time','Rule','Switch','Congruency',
%                   'Switch Distance','Normalized Switch Distance',
%                   'Spline Switch Distance','Error Distance','Normalized Error Distance',
%                   'Spline Error Distance', 'Test Stimulus','Rule Cues',
%                   'Test Stimulus Color','Test Stimulus Orientation','Normalized Prep Time',
%                   'Response Direction','Previous Error Indicator', 'Rule * Test
%                    Stimulus', 'Rule * Previous Error Indicator',
%                   'Previous Error Indicator * Response Direction',
%                   'Rule * Normalized Prep Time', 'Rule * Switch',
%                   'Rule * Response Direction'
%
% timePeriod:'Rule Preparatory Period', 'Stimulus Response', 'Rule Response'
% overwrite: true, *false* (optional)
% includeIncorrect: true, *false* (optional)
% inoTimeInteraction: {}, any valid covariate (optional)

function [gamJob] = GAMcluster(regressionModel_str, timePeriod, varargin)

%% Validate Parameters
main_dir = getWorkingDir();

% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), ...
    'data_info', 'cov_info', 'validFolders', 'session_names', ...
    'monkey_names', 'validPredType');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, validFolders)));
inParser.addParameter('numFolds', 10, @(x) isnumeric(x) && x > 0)
inParser.addParameter('predType', 'Dev', @(x) any(ismember(x, validPredType)))
inParser.addParameter('smoothLambda', 10.^(-3:1:3), @isvector)
inParser.addParameter('ridgeLambda', 10.^(-3:1:3), @isvector)
inParser.addParameter('overwrite', false, @islogical)
inParser.addParameter('includeIncorrect', false, @islogical);
inParser.addParameter('includeFixationBreaks', false, @islogical);
inParser.addParameter('includeTimeBeforeZero', false, @islogical);
inParser.addParameter('isPrediction', false, @islogical);
inParser.addParameter('isLocal', false, @islogical);

inParser.parse(regressionModel_str, timePeriod, varargin{:});

% Add parameters to input structure after validation
gamParams = inParser.Results;

%% Process Data
fprintf('\nProcessing Model: %s\n', regressionModel_str);
gamJob = [];

if gamParams.isLocal,
    % Run Locally
    for session_ind = 1:length(session_names),
        fprintf('\t...Session: %s\n', session_names{session_ind});
        args = struct2args(gamParams);
        ComputeGAMfit(session_names{session_ind}, args{:});
    end
else
    % Use Cluster
    constantArgs = {struct2args(gamParams)};
    args = cellfun(@(x) [x; constantArgs{:}]', session_names, 'UniformOutput', false);
    gamJob = TorqueJob('ComputeGAMfit', args, ...
        'walltime=24:00:00,mem=16GB');
end

end