% Constructs GLMCovariates for use with GLMfit
function [] = SetupGLMCov_cluster(session_name, timePeriod, numLags, varargin)

%% Load Common Parameters and Parse Inputs
main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), 'cov_info');

inParser = inputParser;
inParser.addParameter('overwrite', false, @islogical);

inParser.parse(varargin{:});

glmCovParams = inParser.Results;

%% Check if File Exists Already
save_file_name = sprintf('%s/Processed Data/%s/GLMCov/%s_GLMCov.mat', main_dir, timePeriod, session_name);
if (exist(save_file_name, 'file') && ~glmCovParams.overwrite),
    fprintf('File %s already exists. Skipping.\n', save_file_name);
    return;
end
%% Load Data and Behavior File
dataSessionFile = sprintf('%s/Processed Data/%s/%s_data.mat', main_dir, timePeriod, session_name);
fprintf('\nProcessing file %s...\n', session_name);
load(dataSessionFile);

fprintf('\nLoading behavior...\n');
behaviorFile = sprintf('%s/Behavior/behavior.mat', main_dir);
load(behaviorFile);

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

% 1. Prep Time
Prep_Time = Prep_Time(trial_id);
GLMCov(ismember({cov_info.name}, 'Prep Time')).data =  Prep_Time;

% 2. Rule
GLMCov(ismember({cov_info.name}, 'Rule')).data =  Rule(trial_id);

% 3. Switch
GLMCov(ismember({cov_info.name}, 'Switch')).data = Rule_Switch(trial_id);

% 4. Congruency
GLMCov(ismember({cov_info.name}, 'Congruency')).data = Congruency(trial_id);

% 5. Test Stimulus
GLMCov(ismember({cov_info.name}, 'Test Stimulus')).data = Test_Stimulus(trial_id);

% 6. Rule Cues
GLMCov(ismember({cov_info.name}, 'Rule Cues')).data = Rule_Cues(trial_id);

% 7. Rule Cue Switch
GLMCov(ismember({cov_info.name}, 'Rule Cue Switch')).data = Rule_Cue_Switch(trial_id);

% 8. Test Stimulus Color
GLMCov(ismember({cov_info.name}, 'Test Stimulus Color')).data = Test_Stimulus_Color(trial_id);

% 9. Test Stimulus Orientation
GLMCov(ismember({cov_info.name}, 'Test Stimulus Orientation')).data = Test_Stimulus_Orientation(trial_id);

% 10. Normalized Prep Time
GLMCov(ismember({cov_info.name}, 'Normalized Prep Time')).data = Normalized_Prep_Time(trial_id);

% 11. Response Direction
GLMCov(ismember({cov_info.name}, 'Response Direction')).data = Response_Direction(trial_id);

% 12. Previous Error
GLMCov(ismember({cov_info.name}, 'Previous Error')).data = Previous_Error(trial_id);

% 13. Previous Error History
GLMCov(ismember({cov_info.name}, 'Previous Error History')).data = Previous_Error_History(trial_id, :);

% 14. Rule Repetition
GLMCov(ismember({cov_info.name}, 'Rule Repetition')).data = Rule_Repetition(trial_id, :);

% 15. Trial Time
GLMCov(ismember({cov_info.name}, 'Trial Time')).data = trial_time;

% 16. Switch Distance
GLMCov(ismember({cov_info.name}, 'Switch Distance')).data = dist_sw(trial_id);

% 17. Error Distance
GLMCov(ismember({cov_info.name}, 'Error Distance')).data = dist_err(trial_id);

% 18. Congruency History
GLMCov(ismember({cov_info.name}, 'Congruency History')).data = Congruency_History(trial_id, :);

% 19. Indicator Prep Time
GLMCov(ismember({cov_info.name}, 'Indicator Prep Time')).data = Indicator_Prep_Time(trial_id);

% 20. Previous Congruency
GLMCov(ismember({cov_info.name}, 'Previous Congruency')).data = Previous_Congruency(trial_id);

% 22. Previous Error History Indicator - non-cumulative errors
GLMCov(ismember({cov_info.name}, 'Previous Error History Indicator')).data = Previous_Error_History_Indicator(trial_id);

% 23. Session Time
GLMCov(ismember({cov_info.name}, 'Session Time')).data = Session_Time(trial_id);

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

% 21. Spike History
GLMCov(ismember({cov_info.name}, 'Spike History')).data = spike_hist;

%% Find which areas correspond to PFC
% isa5 is a special case
if strcmp(session_name, 'isa5'),
    pfc = wire_number <= 16;
else
    pfc = wire_number <= 8;
end

%% Save Everything
fprintf('/n Saving.... /n');
save_dir = sprintf('%s/Processed Data/%s/GLMCov', main_dir, timePeriod);
if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end

save(save_file_name, 'GLMCov', 'spikes', 'sample_on', ...
    'numNeurons', 'trial_id', 'trial_time', 'percent_trials', ...
    'wire_number', 'unit_number', 'pfc', 'isCorrect', 'isAttempted', '-v7.3');

end