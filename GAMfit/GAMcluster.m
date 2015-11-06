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
    'covInfo', 'timePeriodNames', 'sessionNames', ...
    'monkeyNames', 'validPredType');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, timePeriodNames)));
inParser.addParameter('numFolds', 5, @(x) isnumeric(x) && x > 0)
inParser.addParameter('predType', 'Dev', @(x) any(ismember(x, validPredType)))
inParser.addParameter('smoothLambda', 10.^(-3), @isvector)
inParser.addParameter('ridgeLambda', 10.^(-3), @isvector)
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
    for session_ind = 1:length(sessionNames),
        fprintf('\t...Session: %s\n', sessionNames{session_ind});
        ComputeGAMfit(sessionNames{session_ind}, gamParams, covInfo);
    end
else
    fprintf('Updating model list...\n');
    modelListJob = TorqueJob('updateModelList', {{gamParams}}); 
    waitMatorqueJob(modelListJob, 'pauseTime', 60);
    % Use Cluster
    fprintf('Fitting model....\n');
    args = cellfun(@(x) {x; gamParams; covInfo}', sessionNames, 'UniformOutput', false);
    gamJob = TorqueJob('ComputeGAMfit', args, ...
        'walltime=24:00:00,mem=120GB,nodes=1:ppn=12');
end

end