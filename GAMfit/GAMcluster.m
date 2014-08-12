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

function GAMcluster(regressionModel_str, timePeriod, main_dir, varargin)

%% Validate Parameters

% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), ...
    'data_info', 'cov_info', 'validFolders', 'session_names', 'numMaxLags', 'monkey_names');

validPredType = {'Dev', 'AUC', 'MI', 'AIC', 'GCV', 'BIC', 'UBRE'};

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, validFolders)));
inParser.addParamValue('numFolds', 10, @(x) isnumeric(x) && x > 0)
inParser.addParamValue('predType', 'Dev', @(x) any(ismember(x, validPredType)))
inParser.addParamValue('smoothLambda', 10.^(-3:1:3), @isvector)
inParser.addParamValue('ridgeLambda', 10.^(-3:1:3), @isvector)
inParser.addParamValue('overwrite', false, @islogical)
inParser.addParamValue('includeIncorrect', false, @islogical);
inParser.addParamValue('includeBeforeTimeZero', false, @islogical);

inParser.parse(regressionModel_str, timePeriod, varargin{:});

% Add parameters to input structure after validation
gamParams = inParser.Results;

if all(size(gamParams.ridgeLambda) ~= size(gamParams.smoothLambda)),
    error('ridgeLambda must equal smoothLambda'); 
end

%% Setup Data Directories and Cluster Job Manager

% Specify Cluster Profile
jobMan = parcluster();

% Specify Home and Data Directory
timePeriod_dir = sprintf('%s/%s', data_info.processed_dir, timePeriod);
save_dir = sprintf('%s/Models/%s', timePeriod_dir, gamParams.regressionModel_str);

if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end

%% Create or Open Log File
log_file = sprintf('%s/Log.log', save_dir);
fileID = fopen(log_file, 'w+');

% Load the covariate file to process
fprintf(fileID, '\n------------------------\n');
fprintf(fileID, '\nDate: %s\n \n', datestr(now));
fprintf(fileID, '\nGAM Parameters\n');
fprintf(fileID, '\t regressionModel_str: %s\n', gamParams.regressionModel_str);
fprintf(fileID, '\t timePeriod: %s\n', gamParams.timePeriod);
fprintf(fileID, '\t numFolds: %d\n', gamParams.numFolds);
fprintf(fileID, '\t ridgeLambda: %d\n', gamParams.ridgeLambda);
fprintf(fileID, '\t smoothLambda: %d\n', gamParams.smoothLambda);
fprintf(fileID, '\t overwrite: %d\n', gamParams.overwrite);
fprintf(fileID, '\t includeIncorrect: %d\n', gamParams.includeIncorrect);

%% Process Data
fprintf('\nProcessing Model: %s\n', regressionModel_str);
gamJob = cell(1, length(session_names));
GAMfit_names = strcat(session_names, '_GAMfit.mat');

% Loop through files in the data directory
for session_ind = 1:length(session_names),
    
    if exist(sprintf('%s/%s', save_dir, GAMfit_names{session_ind}), 'file') && ~gamParams.overwrite,
       continue;
    end
    
    fprintf('\t...Session: %s\n', session_names{session_ind});
    gamJob{session_ind} = createCommunicatingJob(jobMan, 'AdditionalPaths', {data_info.script_dir}, 'AttachedFiles', ...
        {which('saveMillerlab')}, 'NumWorkersRange', [12 12], 'Type', 'Pool');
    
    createTask(gamJob{session_ind}, @ComputeGAMfit, 0, {timePeriod_dir, session_names{session_ind}, gamParams, save_dir});
    submit(gamJob{session_ind});
    pause(1);  
end

fclose(fileID);

end