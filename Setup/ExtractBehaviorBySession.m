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

function [behaviorData] = ExtractBehaviorBySession(sessionName, reactBounds, ...
    trialInfo, covInfo, encodeMap, numErrorLags, numRepetitionLags)

% Load Common Parameters
mainDir = getWorkingDir();

% Find trials file that corresponds to extracted data
fprintf('\nProcessing file %s...\n', sessionName);
sessionFile = sprintf('%s/Raw Data/%s.sdt', mainDir, sessionName);

fprintf('\tLoading data...\n');
load('-mat', sessionFile, 'trials', 'numtrials', 'cells', 'lfps');

behaviorData = containers.Map();

curMonkey = upper(regexprep(sessionName, '\d+', ''));

%% Figure out timing of encodes
encodes = {trials.Encodes};
encodeTimes = {trials.EncodeTimes};

behaviorData('Intertrial Interval Time') = findTimeDiff(encodeMap('Intertrial Interval'));
behaviorData('Fixation Accquired Time') = findTimeDiff({trialInfo('Fixation ON Encode'), trialInfo('Fixation ACQUIRED Encode')});
behaviorData('Fixation Time') = findTimeDiff(encodeMap('Fixation'));
behaviorData('Preparation Time') = findTimeDiff(encodeMap('Rule Stimulus'));
behaviorData('Reaction Time') = findTimeDiff({trialInfo('Test Stimulus ON Encode'), trialInfo('Saccade START Encode')});
behaviorData('Saccade Fixation Time') = findTimeDiff(encodeMap('Saccade'));
behaviorData('Saccade Fixation Time') = findTimeDiff(encodeMap('Saccade'));
behaviorData('Reward Time') = findTimeDiff(encodeMap('Reward'));
cov.data = 1:numtrials;
behaviorData('Trial Number') = cov;

consistent = nan(numtrials,1);

%% Find consistent attempts
for cur_trial = 1:numtrials,
    % find the five trials before the current trial and the five trials after
    surroundingTrials_ind = cur_trial + [-5:5];
    surroundingTrials_ind(surroundingTrials_ind == cur_trial) = [];
    
    % eliminate trials from the index which do not exist
    surroundingTrials_ind(surroundingTrials_ind <= 0 | surroundingTrials_ind > numtrials) = [];
    numPossibleTrials = length(surroundingTrials_ind);
    
    % find the reaction time
    surroundingReact = behaviorData('Reaction Time').data(surroundingTrials_ind);
    
    % Throwout trials in which the monkey guesses based on reaction time
    % bounds defined by the user (eliminates outliers from reaction time
    % distribution)
    % Throwout trials in which the monkey breaks fixation or makes an error
    isBadTrial = (reactBounds(1) > surroundingReact) ...
        | (surroundingReact > reactBounds(2)) ...
        | ismember([trials(surroundingTrials_ind).ResponseError], [trialInfo('Fixation Break'), trialInfo('Incorrect')]);
    
    % Only want trials that are consistent attempts, i.e. 80% of
    % the surrounding trials yield a correct or incorrect, not a break
    % fixation or no fixation and exist within the prep time window
    % specified
    consistent(cur_trial) = sum(isBadTrial) < (numPossibleTrials * 0.2);
end

% Consistent
cov.data = consistent';
behaviorData('Consistent') = cov;
clear cov;
%% Condition
condition = [trials.Condition]';
isCondition = @(condName) ismember(condition, trialInfo(condName));
cov.data = condition;
behaviorData('Condition') = cov;
clear cov;
%% File Name
cov.data = repmat({sessionName}, [1 numtrials]);
behaviorData('Session Name') = cov;
clear cov;
%% Monkey
cov.data = repmat({curMonkey}, [1 numtrials]);
behaviorData('Monkey') = cov;
clear cov;
%% Rule
cov.data = nan(numtrials, 1);
covName = 'Rule';
for level_ind = 1:length(covInfo(covName).levels),
    levelName = covInfo(covName).levels{level_ind};
    cov.data(isCondition(sprintf('%s:%s', covName, levelName))) = find(ismember(covInfo(covName).levels, levelName));
end
behaviorData(covName) = cov;
clear cov;
%% Congruency
cov.data = nan(numtrials, 1);
covName = 'Congruency';
for level_ind = 1:length(covInfo(covName).levels),
    levelName = covInfo(covName).levels{level_ind};
    cov.data(isCondition(sprintf('%s:%s', covName, levelName))) = find(ismember(covInfo(covName).levels, levelName));
end
behaviorData(covName) = cov;
clear cov;
%% Test Stimulus
cov.data = nan(numtrials, 1);
covName = 'Test Stimulus';
for level_ind = 1:length(covInfo(covName).levels),
    levelName = covInfo(covName).levels{level_ind};
    cov.data(isCondition(sprintf('%s:%s', covName, levelName))) = find(ismember(covInfo(covName).levels, levelName));
end
behaviorData(covName) = cov;
clear cov;
%% Identity of rule cues
cov.data = nan(numtrials, 1);
covName = 'Rule Cues';
for level_ind = 1:length(covInfo(covName).levels),
    levelName = covInfo(covName).levels{level_ind};
    cov.data(isCondition(sprintf('%s:%s', covName, levelName))) = find(ismember(covInfo(covName).levels, levelName));
end
behaviorData(covName) = cov;
clear cov;
%% Switch Trials
difference = diff(behaviorData('Rule').data);
switc = zeros(1, numtrials);
switc(find(abs(difference) > 0) + 1) = 1;
cov.data = grp2idx(switc);
behaviorData('Switch') = cov;
clear cov;
%% Correct Trials
cov.data = ismember([trials.ResponseError], trialInfo('Correct'))';
behaviorData('Correct') = cov;
clear cov;
%% Incorrect Trials
cov.data = ismember([trials.ResponseError], trialInfo('Incorrect'))';
behaviorData('Incorrect') = cov;
clear cov;
%% Attempted Trials
cov.data = ismember([trials.ResponseError], [trialInfo('Correct') trialInfo('Incorrect')]) ...
    & behaviorData('Reaction Time').data > reactBounds(1) ...
    & behaviorData('Reaction Time').data < reactBounds(2);
behaviorData('Attempted') = cov;
clear cov;
%% Fixation Breaks
cov.data = ~ismember([trials.ResponseError], trialInfo('Fixation Break'))';
behaviorData('Fixation Break') = cov;
clear cov;
%% Consistent Attempt
behaviorData('Consistent Attempt') = behaviorData('Consistent').data & ...
    behaviorData('Attempted').data;
%% Brain Area - PFC or ACC
if ~strcmp(sessionName, 'isa5')
    isDLPFC = [cells.WireNumber] <= 8;
    cov.data = cell(size([cells.WireNumber]));
    [cov.data{isDLPFC}] = deal('dlPFC');
    [cov.data{~isDLPFC}] = deal('ACC');
    behaviorData('Neuron Brain Area') = cov;
    isDLPFC = [lfps.WireNumber] <= 8;
    cov.data = cell(size([lfps.WireNumber]));
    [cov.data{isDLPFC}] = deal('dlPFC');
    [cov.data{~isDLPFC}] = deal('ACC');
    behaviorData('LFPs Brain Area') = cov;
else
    isDLPFC = [cells.WireNumber] <= 16;
    cov.data = cell(size([cells.WireNumber]));
    [cov.data{isDLPFC}] = deal('dlPFC');
    [cov.data{~isDLPFC}] = deal('ACC');
    behaviorData('Neuron Brain Area') = cov;
    isDLPFC = [lfps.WireNumber] <= 16;
    cov.data = cell(size([lfps.WireNumber]));
    [cov.data{isDLPFC}] = deal('dlPFC');
    [cov.data{~isDLPFC}] = deal('ACC');
    behaviorData('LFPs Brain Area') = cov;
end
%% Number of Neurons and LFPs
behaviorData('Number of Neurons') = length([cells.WireNumber]);
behaviorData('Number of LFPs') = length([lfps.WireNumber]);
%% Correct Saccade Direction
cov.data = nan(numtrials, 1);
covName = 'Saccade';
for level_ind = 1:length(covInfo(covName).levels),
    levelName = covInfo(covName).levels{level_ind};
    cov.data(isCondition(sprintf('%s:%s', covName, levelName))) = find(ismember(covInfo(covName).levels, levelName));
end
behaviorData('Saccade') = cov;
clear cov;
%% Monkey's saccade direction
cov.data = grp2idx(...
    (ismember(condition, trialInfo('Saccade:Left')) & ismember([trials.ResponseError]', trialInfo('Correct'))) ...
    | (~ismember(condition, trialInfo('Saccade:Left')) & ismember([trials.ResponseError]', trialInfo('Incorrect'))) ...
    );

behaviorData('Response Direction') = cov;
%% Rule Cue Switch
difference = diff(behaviorData('Rule Cues').data) ~= 0;
switc = zeros(1,numtrials);
switc(find(abs(difference) > 0)+1) = 1;
cov.data = grp2idx(switc);
behaviorData('Rule Cue Switch') = cov;
clear cov;
%% Previous Error
cov.data = lagmatrix(grp2idx(behaviorData('Incorrect').data), 1);
cov.data(isnan(cov.data)) = 1;
behaviorData('Previous Error') = cov;
clear cov;
%% Previous Error History
cov.data = lagmatrix(grp2idx(behaviorData('Incorrect').data), 1:numErrorLags);
cov.data(isnan(cov.data)) = 1;
behaviorData('Previous Error History') = cov;
clear cov;
%% Distance from Switch
ruleRep = nan(size(behaviorData('Switch').data));
sw = find(behaviorData('Switch').data == 2);
num = diff(sw);

for sw_ind = 1:length(sw)+1
    if sw_ind == 1
        ruleRep(1:sw(sw_ind)) = 0:sw(sw_ind)-1;
    elseif sw_ind ~= length(sw)+1
        ruleRep(sw(sw_ind-1):(sw(sw_ind-1) + num(sw_ind-1) - 1)) = 0:num(sw_ind-1)-1;
    else
        ruleRep(sw(sw_ind-1):end) = 0:(length(ruleRep) - sw(sw_ind-1));
    end
end
ruleRep = ruleRep + 1;
cov.data = ruleRep;
behaviorData('Switch Distance') = cov;
clear cov;
%% Rule Repetition - number of repetitions up to a number
cov.data = behaviorData('Switch Distance').data;
cov.data(cov.data >= numRepetitionLags) = numRepetitionLags;
behaviorData('Rule Repetition') = cov;
clear cov;
%% Distance from Error
dist_err = nan(size(behaviorData('Incorrect').data));
err = find(behaviorData('Incorrect').data);
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

% dist_err(1:find(behaviorData('Incorrect').data, 1) - 1) = numErrorLags;
cov.data = dist_err;
behaviorData('Error Distance') = cov;
clear cov
%% Previous Error History Indicator
% non-cumulative version of error history
dist_err = behaviorData('Error Distance').data;
dist_err(dist_err == 0) = NaN;
dist_err(dist_err >= numErrorLags) = numErrorLags;
cov.data = dist_err;
behaviorData('Previous Error History Indicator') = cov;
clear cov;
%% Session Time
thirds = numtrials*(1/3);
temp = 1:numtrials;
temp(temp <= thirds) = 1; % early in day
temp(temp > thirds & temp <= 2* thirds) = 2; %middle of day
temp(temp > 2* thirds) = 3; %late part of day
cov.data = temp';
behaviorData('Session Time') = cov;
clear cov;
%% Block in Day
cov.data = cumsum(behaviorData('Switch').data - 1) + 1;
behaviorData('Rule Block') = cov;
clear cov;
%% Congruency History
cov.data = lagmatrix(behaviorData('Congruency').data, 0:1);
behaviorData('Congruency History') = cov;
clear cov;
%% Previous Congruency
cov.data = lagmatrix(behaviorData('Congruency').data, 1);
behaviorData('Previous Congruency') = cov;
clear cov;
%% Helper Function 
    function [cov] = findTimeDiff(desiredEncodes)
        findTimeInterval = @(encTime, encs, desiredEnc) sum(diff(encTime(ismember(encs, cell2mat(desiredEnc)))));
        findTimeInteval_AllTrials = @(desiredEnc) cellfun(@(encTime, encs) findTimeInterval(encTime, encs, desiredEnc), encodeTimes, encodes, 'UniformOutput', false);
        time = findTimeInteval_AllTrials(desiredEncodes);
        empt = cellfun(@(x) x == 0, time);
        time(empt) = {NaN};
        cov.data = [time{:}];
    end
end