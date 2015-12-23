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
inParser.addParamValue('numFolds', 5, @(x) isnumeric(x) && x > 0)
inParser.addParamValue('predType', 'Dev', @(x) any(ismember(x, validPredType)))
inParser.addParamValue('smoothLambda', 10.^(-3), @isvector)
inParser.addParamValue('ridgeLambda', 1, @isvector)
inParser.addParamValue('overwrite', false, @islogical)
inParser.addParamValue('includeIncorrect', false, @islogical);
inParser.addParamValue('includeFixationBreaks', false, @islogical);
inParser.addParamValue('includeTimeBeforeZero', false, @islogical);
inParser.addParamValue('isPrediction', false, @islogical);
inParser.addParamValue('isLocal', false, @islogical);

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
        'walltime=90:00:00,mem=124GB,nodes=1:ppn=12', true, 'numOutputs', 0);
end

end