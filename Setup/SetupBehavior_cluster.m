% Creates single structure containing relevant behavioral data and
% a logical index (monkey) defining the monkey recorded from

% INPUTS:
%       data_dir:       the directory of sdt files from which the structure is
%                       created
%       react_bounds:   a 2x1 matrix defining the minimum and maximum
%                       allowable reaction time.

% OUTPUTS:
%       monkey - monkey recorded from on specific day
%            0 Monkey ISA
%            1 Monkey CC
%       index - structure containing relevant behavioral data
%           name - name of file
%           consistent_attempt - consistent + attempted (see below)
%           reaction time - time from sample cue to choice
%           norm reaction - time from sample cue to choice normalized by
%                           the 10 surrounding trials (5 before, 5 after)
%           consistent - 80% of the surrounding trials yielded a correct or
%                        incorrect, not a break in fixation/no fixation or
%                       a guess (reaction time < 100 ms or reaction time > 313 ms)
%           color
%                    0 Orientation Trial
%                    1 Color Trial
%           day - number from 1 - length of files defining the day of
%                 recording
%           switch
%                    0 Repetition Trial - rule of trial before is the same
%                    1 Switch Trial - rule of trial before is different
%           dist_sw - number of trials from rule change, first trial after
%                     switch is zero, second trial is one, etc.
%           otc_switch - switch trials that go from orientation to color
%           cto_switch - switch trials that go from color to orientation
%           correct - correct trials
%           incorrect - incorrect trials
%           attempted - only correct and incorrect trials
%           condition - same as trials.Condition
%           pfc
%               1 electrode in ACC
%               2 electrode in PFC
%           incongruent
%               1 congruent samples
%               2 incongruent samples
%           condition_left
%               1 correct answer is saccade right
%               2 correct answer is saccade left
%           sample_ident - sample identities
%               1 Vertical Blue
%               2 Vertical Red
%               3 Horizontal Blue
%               4 Horizontal Red
%           monkey_choose_left
%               1 monkey saccade right
%               2 monkey saccade left
%           monkey
%               1 ISA
%               2 CH
%               3 CC
%           color_cues - identity of color rule cues
%               1 Cue4.bmp and 26 x 36 Black sq
%               2 Only 26 x 36 black sq
%           orient_cues - identity of orientation rule cues
%               1 Cue3.bmp (w/black)
%               2 37 x 49 Pink Sq and 26 x 36 Black sq

function [behavior] = SetupBehavior_cluster(session_name, main_dir, react_bounds, session_ind)

% Load Common Parameters
load(sprintf('%s/paramSet.mat',main_dir), 'data_info', 'trial_info');

% Find trials file that corresponds to extracted data
fprintf('\nProcessing file %s...\n', session_name);
session_file = sprintf('%s/%s.sdt', data_info.rawData_dir, session_name);

fprintf('\tLoading data...\n');
load('-mat', session_file, 'trials', 'numtrials', 'cells', 'lfps');

% Pre-allocate space
behavior.consistent_attempt = nan(numtrials,1);

curMonkey = upper(regexprep(session_name, '\d+', ''));

% Loop through trials and find prepatory period, reaction times and
% define consistent attempts
for cur_trial = 1:numtrials,
    % If no trial condition, code as NaN
    if isempty(trials(cur_trial).Condition)
        trials(cur_trial).Condition = NaN;
    end
    if isempty(trials(cur_trial).ResponseError)
        trials(cur_trial).ResponseError = NaN;
    end
    
    % Intertrial Interval
    temp = trials(cur_trial).EncodeTimes(ismember(trials(cur_trial).Encodes, [trial_info.FixationOn_encode]));
    if isempty(temp)
        behavior.ITI_Time(cur_trial, 1) = NaN;
    else
        behavior.ITI_Time(cur_trial, 1) = temp;
    end
    
    % fixation spot on to fixation accquired
    temp = diff(trials(cur_trial).EncodeTimes(ismember(trials(cur_trial).Encodes, [trial_info.FixationOn_encode trial_info.FixationAccquired_encode])));
    if isempty(temp)
        behavior.fixOn_time(cur_trial, 1) = NaN;
    else
        behavior.fixOn_time(cur_trial, 1) = temp;
    end
    
    % fixation accquired to rule cue
    temp = diff(trials(cur_trial).EncodeTimes(ismember(trials(cur_trial).Encodes, [trial_info.FixationAccquired_encode trial_info.RuleOn_encode])));
    if isempty(temp)
        behavior.Fix_Time(cur_trial, 1) = NaN;
    else
        behavior.Fix_Time(cur_trial, 1) = temp;
    end
    
    % prep_time - time from rule onset to sample onset
    temp = diff(trials(cur_trial).EncodeTimes(ismember(trials(cur_trial).Encodes, [trial_info.RuleOn_encode trial_info.SampleOn_encode])));
    if isempty(temp)
        behavior.Prep_Time(cur_trial, 1) = NaN;
    else
        behavior.Prep_Time(cur_trial, 1) = temp;
    end
    
    % reaction times - time from sample onset to choice onset
    temp = diff(trials(cur_trial).EncodeTimes(ismember(trials(cur_trial).Encodes, [trial_info.SampleOn_encode trial_info.SaccadeStart_encode])));
    if isempty(temp)
        behavior.Reaction_Time(cur_trial, 1) = NaN;
    else
        behavior.Reaction_Time(cur_trial, 1) = temp;
    end
    
    % saccade start to reward start
    temp = diff(trials(cur_trial).EncodeTimes(ismember(trials(cur_trial).Encodes, cell2mat([trial_info.SaccadeStart_encode trial_info.RewardStart_encode]))));
    if isempty(temp) | temp < 0,
        behavior.Saccade_Time(cur_trial, 1) = NaN;
    else
        behavior.Saccade_Time(cur_trial, 1) = sum(temp);
    end
    
    % Reward to End
    temp = diff(trials(cur_trial).EncodeTimes(ismember(trials(cur_trial).Encodes, [trial_info.Reward_encode trial_info.End_encode])));
    if isempty(temp)
        behavior.Reward_Time(cur_trial, 1) = NaN;
    else
        temp = sum(temp);
        behavior.Reward_Time(cur_trial, 1) = temp;
    end
    
     % noReward to End
    temp = diff(trials(cur_trial).EncodeTimes(ismember(trials(cur_trial).Encodes, [trial_info.noReward_encode trial_info.End_encode])));
    if isempty(temp)
        behavior.noReward_time(cur_trial, 1) = NaN;
    else
        temp = sum(temp);
        behavior.noReward_time(cur_trial, 1) = temp;
    end
    
    temp = trials(cur_trial).EncodeTimes(ismember(trials(cur_trial).Encodes, 45));
    % Want to mark trials in which the monkey made a second saccade
    if isempty(temp)
        behavior.second_saccade(cur_trial, 1) = 0;
    else
        saccade_time = (temp-10):temp;
        eye_pos = trials(cur_trial).EyeData;
        eye_velocity = ([zeros(1,3); diff(eye_pos)]);
        
        smooth_param = 10;
        conv_filt = normpdf([-5*smooth_param:5*smooth_param], 0, smooth_param);
        smooth_velocity  = conv2(conv_filt, 1, eye_velocity, 'same');
        if strcmp(curMonkey, 'ISA') || strcmp(curMonkey, 'CH'),
            x = 2;
            y = 3;
        else
            x = 3;
            y = 2;
        end
        
        [~, r_smooth] = cart2pol(smooth_velocity(:,x), smooth_velocity (:,y));
        behavior.second_saccade(cur_trial, 1) = nanmean(r_smooth(saccade_time)/max(r_smooth)) > .25;
    end
    
    
    % find the five trials before the current trial and the five trials after
    before_trial_after_ind = cur_trial+[-5:5];
    before_trial_after_ind(6) = [];
    
    % eliminate trials from the index which do not exist
    before_trial_after_ind(before_trial_after_ind <= 0 | before_trial_after_ind > numtrials) = [];
    numPossibleTrials = length(before_trial_after_ind);
    
    % find the reaction time
    EncodeTimes = {trials(before_trial_after_ind).EncodeTimes};
    Encode_idx = cellfun(@(x) find(ismember(x, [trial_info.SampleOn_encode trial_info.SaccadeStart_encode])), {trials(before_trial_after_ind).Encodes}, 'UniformOutput', false);
    surrounding_react = cellfun(@(x,y) diff(x(y)), EncodeTimes, Encode_idx, 'UniformOutput', false);
    
    % Throwout trials in which the monkey guesses based on reaction time
    % bounds defined by the user (eliminates outliers from reaction time
    % distribution)
    good_choice_idx = cellfun(@(x) x > react_bounds(1) & x < react_bounds(2), surrounding_react, 'UniformOutput', false);
    surrounding_react = cellfun(@(x,y) x(y), surrounding_react, good_choice_idx, 'UniformOutput', false);
    
    % Throwout trials in which the monkey breaks fixation or makes an error
    surrounding_react(ismember([trials(before_trial_after_ind).ResponseError], [trial_info.FixationBreak trial_info.Incorrect])) = [];
    
    % Only want trials that are consistent attempts, i.e. 80% of
    % the surrounding trials yield a correct or incorrect, not a break
    % fixation or no fixation and exist within the prep time window
    % specified
    behavior.consistent(cur_trial, 1) =  (length(surrounding_react) >= numPossibleTrials*0.8);
    
end

% For each trial, define the trial information
cond = [trials.Condition]';
% File Name
behavior.session_name = session_name;
% Day of recording
behavior.day = session_ind*ones(numtrials, 1);
% Monkey
behavior.monkey = repmat({curMonkey}, [numtrials 1]);
% Consistent
behavior.consistent = logical(behavior.consistent);
% Rule
behavior.Rule = grp2idx(ismember(cond, trial_info.Rule_color));

% Switch Trials
difference = diff(behavior.Rule);
switc = zeros(1,numtrials);
switc(find(difference)+1) = 1;
behavior.Switch = grp2idx(switc);
% Correct and Incorrect Trials
behavior.correct =  ismember([trials.ResponseError], trial_info.Correct)';
behavior.incorrect = ismember([trials.ResponseError], trial_info.Incorrect)';
% Attempted Trials
behavior.attempted = ismember([trials.ResponseError], [trial_info.Correct trial_info.Incorrect])' ...
    & behavior.Reaction_Time > react_bounds(1) ...
    & behavior.Reaction_Time < react_bounds(2);
% Fixation Breaks
behavior.fixationBreak = ~ismember([trials.ResponseError], [trial_info.Correct trial_info.Incorrect]);
% Consistent Attempt
behavior.consistent_attempt = behavior.consistent & ...
    behavior.attempted;
% Trial Condition
behavior.condition = cond;
% Brain Area - PFC or ACC
if ~strcmp(session_name, 'isa5')
    behavior.pfc_neurons = [cells.WireNumber] <= 8;
    behavior.pfc_lfps = [lfps.WireNumber] <= 8;
else
    behavior.pfc_neurons = [cells.WireNumber] <= 16;
    behavior.pfc_lfps = [lfps.WireNumber] <= 16;
end
% Number of Neurons, LFPs
behavior.numNeurons = length(cells);
behavior.numLFPs = length(lfps);
% Congruent
behavior.Congruency = grp2idx(ismember(cond, [trial_info.Stimulus_vertRed trial_info.Stimulus_horzBlue]));
% Test Stimulus
sample_ident = nan(numtrials, 1);
sample_ident(ismember(cond, trial_info.Stimulus_vertBlue)) = 1; %vert_blue
sample_ident(ismember(cond, trial_info.Stimulus_vertRed)) = 2; %vert_red
sample_ident(ismember(cond, trial_info.Stimulus_horzBlue)) = 3; %horz_blue
sample_ident(ismember(cond, trial_info.Stimulus_horzRed)) = 4; %horz_red

behavior.Test_Stimulus = sample_ident;

% Test Stimulus Direction / Color
behavior.Test_Stimulus_Orientation = grp2idx(ismember(cond, [trial_info.Stimulus_vertRed trial_info.Stimulus_vertBlue])); % vert
behavior.Test_Stimulus_Color = grp2idx(ismember(cond, [trial_info.Stimulus_vertRed trial_info.Stimulus_horzRed])); % red

behavior.condition_left = grp2idx(ismember(cond, trial_info.Saccade_left));

% Monkey's saccade direction
behavior.Response_Direction = grp2idx((ismember(cond, trial_info.Saccade_left) ...
    & ismember([trials.ResponseError]', trial_info.Correct)) | (~ismember(cond, trial_info.Saccade_left) ...
    & ismember([trials.ResponseError]', trial_info.Incorrect)));

% Identity of rule cues
rule_cue = nan(numtrials, 1);

rule_cue(ismember(cond, trial_info.Rule_color1)) = 1; %16 6 Cue4.bmp 26 x 36 Black sq
rule_cue(ismember(cond, trial_info.Rule_color2)) = 2; %6 Only 26 x 36 black sq
rule_cue(ismember(cond, trial_info.Rule_orient1)) = 3; %15 6 Cue3.bmp(w/black)
rule_cue(ismember(cond, trial_info.Rule_orient2)) = 4; %5 6 37 x 49 Pink Sq 26 x 36 Black sq

behavior.Rule_Cues = rule_cue;

% Rule Cue Switch
difference = diff(behavior.Rule_Cues) ~= 0;
switc = zeros(1,numtrials);
switc(find(difference)+1) = 1;
behavior.Rule_Cue_Switch = grp2idx(switc);

% Previous Error up to lag 10
behavior.Previous_Error = lagmatrix(grp2idx(behavior.incorrect), 1);
behavior.Previous_Error_History = lagmatrix(grp2idx(behavior.incorrect), 1:10);
behavior.Previous_Error_History(isnan(behavior.Previous_Error_History)) = 1;
% Distance from Switch
dist_sw = nan(size(behavior.Switch));
sw = find(behavior.Switch == 2);
num = diff(sw);

for sw_ind = 1:length(sw)+1
    if sw_ind == 1
        dist_sw(1:sw(sw_ind)) = 0:sw(sw_ind)-1;
    elseif sw_ind ~= length(sw)+1
        dist_sw(sw(sw_ind-1):(sw(sw_ind-1) + num(sw_ind-1) - 1)) = 0:num(sw_ind-1)-1;
    else
        dist_sw(sw(sw_ind-1):end) = 0:(length(dist_sw) - sw(sw_ind-1));
    end
end
dist_sw = dist_sw+1;
behavior.dist_sw = dist_sw;

dist_sw(dist_sw >= 11) = 11;

% Switch up to lag 10
behavior.Switch_History = dist_sw;

% Distance from Error
dist_err = nan(size(behavior.incorrect));
err = find(behavior.incorrect);
num = diff(err);

for err_ind = 1:length(err)+1
    if err_ind == 1
        dist_err(1:err(err_ind)) = 0:err(err_ind)-1;
    elseif err_ind ~= length(err)+1
        dist_err(err(err_ind-1):(err(err_ind-1) + num(err_ind-1) - 1)) = 0:num(err_ind-1)-1;
    else
        dist_err(err(err_ind-1):end) = 0:(length(dist_err) - err(err_ind-1));
    end
end

dist_err(1:find(behavior.incorrect, 1)-1) = 11;
behavior.dist_err = dist_err;


dist_err(dist_err == 0) = NaN;
dist_err(dist_err >= 11) = 11;

% non-cumulative version of error history
behavior.Previous_Error_History_Indicator = dist_err;

% Trial Time
thirds = numtrials*(1/3);
temp = 1:numtrials;
temp(temp <= thirds) = 1; % early in day
temp(temp > thirds & temp <= 2* thirds) = 2; %middle of day
temp(temp > 2* thirds) = 3; %late part of day
behavior.Trial_Block = temp';

% Block in Day
behavior.block = cumsum(behavior.Switch) + 1;

% Congruency History
behavior.Congruency_History = lagmatrix(behavior.Congruency, 0:1);

% Previous Congruency
behavior.Previous_Congruency = lagmatrix(behavior.Congruency, 1);

end


