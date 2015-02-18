% Constructs GLMCovariates for use with GLMfit
function [] = SetupGLMCov_cluster(session_name, timePeriod, main_dir, numLags, varargin)

%% Load Common Parameters and Parse Inputs
load(sprintf('%s/paramSet.mat', main_dir), ...
    'data_info', 'cov_info', 'validFolders', 'session_names');

inParser = inputParser;
inParser.addRequired('session_name', @(x) ismember(x, session_names));
inParser.addRequired('timePeriod', @(x) any(ismember(x, validFolders)));
inParser.addParamValue('overwrite', false, @islogical);

inParser.parse(session_name, timePeriod, varargin{:});

glmCovParams = inParser.Results;

%% Check if File Exists Already

save_file_name = sprintf('%s/%s/GLMCov/%s_GLMCov.mat', data_info.processed_dir, glmCovParams.timePeriod, session_name);

if (exist(save_file_name, 'file') && ~glmCovParams.overwrite),
    fprintf('File %s already exists. Skipping.\n', save_file_name);
    return;
end

%% Load Data and Behavior File
data_session_file = sprintf('%s/%s/%s_data.mat', data_info.processed_dir, glmCovParams.timePeriod, session_name);
fprintf('\nProcessing file %s...\n', session_name);
load(data_session_file);

fprintf('\nLoading behavior...\n');
beh_file = sprintf('%s/behavior.mat', data_info.behavior_dir);
load(beh_file);

% Get behavior corresponding to this session
beh_ind = ismember({behavior.session_name}, session_name);
behavior = behavior(beh_ind);
%% Setup Covariates

isAttempted = [behavior.attempted];
isCorrect = [behavior.correct];

Prep_Time = behavior.Prep_Time;
Rule = behavior.Rule;
Rule_Switch = behavior.Switch;
Congruency = behavior.Congruency;
Test_Stimulus = behavior.Test_Stimulus;
Rule_Cues = behavior.Rule_Cues;
Rule_Cue_Switch = behavior.Rule_Cue_Switch;
Test_Stimulus_Color = behavior.Test_Stimulus_Color;
Test_Stimulus_Orientation = behavior.Test_Stimulus_Orientation;
Normalized_Prep_Time = behavior.Normalized_Prep_Time;
Response_Direction = behavior.Response_Direction;
Previous_Error = behavior.Previous_Error;
Previous_Error_History = behavior.Previous_Error_History;
Rule_Repetition = behavior.Rule_Repetition;
dist_sw = behavior.dist_sw;
dist_err = behavior.dist_err;
Indicator_Prep_Time = behavior.Indicator_Prep_Time;
Congruency_History = behavior.Congruency_History;
Previous_Congruency = behavior.Previous_Congruency;
Previous_Error_History_Indicator = behavior.Previous_Error_History_Indicator;
Session_Time = behavior.Session_Time;

time = time(:)';
data = data(:)';

%% Do some organizing
spikes = cat(1, data{:});
trial_time = cat(2, time{:})';

numNeurons = size(spikes, 2);

%% What trial does each time correspond to?
trial_id = num2cell(1:size(time, 2));

trial_id = cellfun(@(x,y) x(ones(size(y))), trial_id, time, 'UniformOutput', false);
trial_id = cat(2, trial_id{:})';

%% Label each trial time point with the appropriate covariate
isAttempted = isAttempted(trial_id);
isCorrect = isCorrect(trial_id);
GLMCov = cov_info;

% Prep Time
Prep_Time = Prep_Time(trial_id);
GLMCov(1).data =  Prep_Time;

% Rule
GLMCov(2).data =  Rule(trial_id);

% Switch
GLMCov(3).data = Rule_Switch(trial_id);

% Congruency
GLMCov(4).data = Congruency(trial_id);

% Test Stimulus
GLMCov(5).data = Test_Stimulus(trial_id);

% Rule Cues
GLMCov(6).data = Rule_Cues(trial_id);

% Rule Cue Switch
GLMCov(7).data = Rule_Cue_Switch(trial_id);

% Test Stimulus Color
GLMCov(8).data = Test_Stimulus_Color(trial_id);

% Test Stimulus Orientation
GLMCov(9).data = Test_Stimulus_Orientation(trial_id);

% Normalized Prep Time
GLMCov(10).data = Normalized_Prep_Time(trial_id);

% Response Direction
GLMCov(11).data = Response_Direction(trial_id);

% Previous Error
GLMCov(12).data = Previous_Error(trial_id);

% Previous Error Indicator
GLMCov(13).data = Previous_Error_History(trial_id, :);

% Switch History
GLMCov(14).data = Rule_Repetition(trial_id, :);

% Trial Time
GLMCov(15).data = trial_time;

% Switch Distance
GLMCov(16).data = dist_sw(trial_id);

% Error Distance
GLMCov(17).data = dist_err(trial_id);

% Congruency History
GLMCov(18).data = Congruency_History(trial_id, :);

% Indicator Prep Time
GLMCov(19).data = Indicator_Prep_Time(trial_id);

% Previous Congruency
GLMCov(20).data = Previous_Congruency(trial_id);

% Error History - non-cumulative errors
GLMCov(22).data = Previous_Error_History_Indicator(trial_id);

% Session Time
GLMCov(23).data = Session_Time(trial_id);

% Indicator function for when the test stimulus is on
sample_on = trial_time >= Prep_Time;

% Compute the number of trials for each time point
table = tabulate(trial_time);
percent_trials = nan(size(trial_time));
for time_ind = 1:length(table(:,1))
    percent_trials(trial_time == table(time_ind,1)) = table(time_ind,3);
end

%% Compute the spiking history

% The function lag matrix takes up too much memory if given a large amount
% of memory so break up the data into smaller bits
spike_hist = spalloc(size(spikes, 1), numNeurons*numLags, nansum(nansum(spikes))*numLags);

parts_quant = unique(floor(quantile(1:(numLags+1), [0:0.1:1])));

for parts_ind = 1:(length(parts_quant)-1),
   
    curLags = parts_quant(parts_ind):(parts_quant(parts_ind+1)-1);
    part_hist = lagmatrix(spikes, curLags);
    part_hist(isnan(part_hist)) = 0;
    spike_hist(:, [1:(numNeurons*length(curLags))] + (parts_quant(parts_ind) - 1)*numNeurons) = sparse(part_hist);
    
end

GLMCov(21).data = spike_hist;

%% Find which areas correspond to PFC
% isa5 is a special case
if strcmp(session_name, 'isa5'),
    pfc = wire_number <= 16;
else
    pfc = wire_number <= 8;
end

%% Save Everything

saveMillerlab('edeno', save_file_name, 'GLMCov', 'spikes', 'sample_on', ...
    'numNeurons', 'trial_id', 'trial_time', 'percent_trials', ...
    'wire_number', 'unit_number', 'pfc', 'isCorrect', 'isAttempted', '-v7.3');


end