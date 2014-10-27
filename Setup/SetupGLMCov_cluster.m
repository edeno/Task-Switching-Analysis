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

%% Want only consistent attempts
good_ind = [behavior.attempted];
% good_ind = true(size(data));

data = data(good_ind);
time = time(good_ind);

time = time(:)';
data = data(:)';

prep = behavior.Prep_Time(good_ind);
rule = behavior.Rule(good_ind);
sw = behavior.Switch(good_ind);
incongruent = behavior.Congruency(good_ind);
sample_ident = behavior.Test_Stimulus(good_ind);
rule_cues = behavior.Rule_Cues(good_ind);
rule_cue_switch = behavior.Rule_Cue_Switch(good_ind);
sample_color = behavior.Test_Stimulus_Color(good_ind);
sample_orient = behavior.Test_Stimulus_Orientation(good_ind);
norm_prep = behavior.Normalized_Prep_Time(good_ind);
left_choice = behavior.Response_Direction(good_ind);
prev_error = behavior.Previous_Error(good_ind);
prev_error_indicator = behavior.Previous_Error_History(good_ind, :);
switch_indicator = behavior.Switch_History(good_ind, :);
switch_dist = behavior.dist_sw(good_ind);
err_dist = behavior.dist_err(good_ind);
incorrect = behavior.incorrect(good_ind);
indicator_prep = behavior.Indicator_Prep_Time(good_ind);
congruency_history = behavior.Congruency_History(good_ind, :);
prev_congruency = behavior.Previous_Congruency(good_ind);
error_hist_indicator = behavior.Previous_Error_History_Indicator(good_ind);

%% Do some organizing
spikes = cat(1, data{:});
trial_time = cat(2, time{:})';

numNeurons = size(spikes, 2);

%% What trial does each time correspond to?
Csize = cell2mat(cellfun(@length, time, 'UniformOutput', false));

trial_id = zeros(size(trial_time));
cum_num = cumsum(Csize);
trial_id(cum_num(1:end-1)+1) = 1;
trial_id(1) = 1;
trial_id = cumsum(trial_id);

% There's a weird case where if the last couple trials are empty, trial id
% counts too many
trial_id(ismember(trial_id, find(histc(trial_id, 1:max(trial_id)) == 1))) = [];

%% Label each trial time point with the appropriate covariate
incorrect = incorrect(trial_id)';
GLMCov = cov_info;

% Prep Time
prep = prep(trial_id);
GLMCov(1).data =  prep;

% Rule
GLMCov(2).data =  rule(trial_id);

% Switch
GLMCov(3).data = sw(trial_id);

% Congruency
GLMCov(4).data = incongruent(trial_id);

% Test Stimulus
GLMCov(5).data = sample_ident(trial_id);

% Rule Cues
GLMCov(6).data = rule_cues(trial_id);

% Rule Cue Switch
GLMCov(7).data = rule_cue_switch(trial_id);

% Test Stimulus Color
GLMCov(8).data = sample_color(trial_id);

% Test Stimulus Orientation
GLMCov(9).data = sample_orient(trial_id);

% Normalized Prep Time
GLMCov(10).data = norm_prep(trial_id);

% Response Direction
GLMCov(11).data = left_choice(trial_id);

% Previous Error
GLMCov(12).data = prev_error(trial_id);

% Previous Error Indicator
GLMCov(13).data = prev_error_indicator(trial_id, :);

% Switch History
GLMCov(14).data = switch_indicator(trial_id, :);

% Trial Time
GLMCov(15).data = trial_time;

% Switch Distance
GLMCov(16).data = switch_dist(trial_id);

% Error Distance
GLMCov(17).data = err_dist(trial_id);

% Congruency History
GLMCov(18).data = congruency_history(trial_id, :);

% Indicator Prep Time
GLMCov(19).data = indicator_prep(trial_id);

% Previous Congruency
GLMCov(20).data = prev_congruency(trial_id);

% Error History - non-cumulative errors
GLMCov(22).data = error_hist_indicator(trial_id);

% Indicator function for when the test stimulus is on
sample_on = trial_time >= prep;

% Compute the number of trials for each time point
[n, bin] = histc(trial_time, min(trial_time):max(trial_time));
percent_trials = sparse(dummyvar(bin))*(n/length(Csize));

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
    'wire_number', 'unit_number', 'pfc', 'incorrect', '-v7.3');


end