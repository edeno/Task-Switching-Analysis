clear all; close all; clc;
cur_file = 'cc1';
drop_dir = getappdata(0, 'drop_path');
data_dir = [drop_dir, '/Generalized Additive Models/APC'];
cd(data_dir);
save_dir = [drop_dir, '/Visualizations/Raster'];
load([data_dir, '/', cur_file, '_GLMCov.mat']);
load('behavior.mat');
clear incorrect;

behavior = behavior(ismember({behavior.session_name}, cur_file));
isAttempted = behavior.attempted;

area_names = {'ACC', 'dlPFC'};
monkey_name = unique(behavior.monkey);

trial_num = unique(trial_id);
numTrials = length(trial_num);

for neuron_ind = 1:numNeurons,
    neurons(neuron_ind)= struct(...
        'Name', sprintf('%s_%d_%d', cur_file, wire_number(neuron_ind), unit_number(neuron_ind)), ...
        'Brain_Area', area_names{pfc(neuron_ind)+1}, ...
        'Monkey', monkey_name, ...
        'File_Name', cur_file, ...
        'Number_of_Trials', numTrials);
end

rule_levels = GLMCov(ismember({GLMCov.name}, 'Rule')).levels;
responseDir_levels = GLMCov(ismember({GLMCov.name}, 'Response Direction')).levels;
previousError_levels = GLMCov(ismember({GLMCov.name}, 'Previous Error')).levels;
congruencyHistory_levels = GLMCov(ismember({GLMCov.name}, 'Congruency History')).levels;
testStimulus_levels = GLMCov(ismember({GLMCov.name}, 'Test Stimulus')).levels;
ruleCue_levels = GLMCov(ismember({GLMCov.name}, 'Rule Cues')).levels;
ruleCueRepetition_levels = GLMCov(ismember({GLMCov.name}, 'Rule Cue Switch')).levels;
incorrect_levels = {'Correct', 'Incorrect'};

behavior.Previous_Error(isnan(behavior.Previous_Error)) = 1;
behavior.Congruency_History(isnan(behavior.Congruency_History)) = 1;

Rule = rule_levels(behavior.Rule);
Preparation_Time = behavior.Prep_Time';
Response_Direction = responseDir_levels(behavior.Response_Direction);
Previous_Error = previousError_levels(behavior.Previous_Error);
Congruency_History = congruencyHistory_levels(behavior.Congruency_History);
Current_Congruency = Congruency_History(:,1);
Previous_Congruency = Congruency_History(:,2);
Test_Stimulus = testStimulus_levels(behavior.Test_Stimulus);
Rule_Cues = ruleCue_levels(behavior.Rule_Cues);
Rule_Cue_Repetition = ruleCueRepetition_levels(behavior.Rule_Cue_Switch);
Incorrect = incorrect_levels(behavior.incorrect + 1);

fixOn_time = behavior.ITI_Time;
ruleOn_time = fixOn_time + behavior.fixOn_time + behavior.Fix_Time; % Fix spot on + fix spot accquired + fixation time
stimOn_time = ruleOn_time + behavior.Prep_Time;
react_time = stimOn_time + behavior.Reaction_Time;
saccade_time = react_time + behavior.Saccade_Time;
reward_time = saccade_time + behavior.Reward_Time;

Rule_Repetition = behavior.Switch_History(isAttempted);
Rule = Rule(isAttempted)';
Response_Direction = Response_Direction(isAttempted)';
Preparation_Time = Preparation_Time(isAttempted)';
Previous_Error = Previous_Error(isAttempted)';
Current_Congruency = Current_Congruency(isAttempted);
Previous_Congruency = Previous_Congruency(isAttempted);
Test_Stimulus = Test_Stimulus(isAttempted)';
Rule_Cues = Rule_Cues(isAttempted)';
Rule_Cue_Repetition = Rule_Cue_Repetition(isAttempted)';
Incorrect = Incorrect(isAttempted)';

fixOn_time = fixOn_time(isAttempted);
ruleOn_time = ruleOn_time(isAttempted);
stimOn_time = stimOn_time(isAttempted);
react_time = react_time(isAttempted);
saccade_time = saccade_time(isAttempted);
reward_time = reward_time(isAttempted);

for trial_ind = 1:numTrials,
    
    cur_trial = ismember(trial_id, trial_num(trial_ind));
    trials(trial_ind).trial_id = trial_num(trial_ind);
    
    trials(trial_ind).start_time = 1;
    trials(trial_ind).fixation_onset = fixOn_time(trial_num(trial_ind));
    trials(trial_ind).rule_onset = ruleOn_time(trial_num(trial_ind));
    trials(trial_ind).stim_onset = stimOn_time(trial_num(trial_ind));
    trials(trial_ind).react_time = react_time(trial_num(trial_ind));
    trials(trial_ind).saccade_time = saccade_time(trial_num(trial_ind));
    trials(trial_ind).reward_time = reward_time(trial_num(trial_ind));
    trials(trial_ind).end_time = max(trial_time(cur_trial));
    
    trials(trial_ind).Rule = Rule{trial_num(trial_ind)};
    trials(trial_ind).Rule_Repetition = Rule_Repetition(trial_num(trial_ind));
    trials(trial_ind).Response_Direction = Response_Direction{trial_num(trial_ind)};
    trials(trial_ind).Current_Congruency = Current_Congruency{trial_num(trial_ind)};
    trials(trial_ind).Previous_Congruency = Previous_Congruency{trial_num(trial_ind)};
    trials(trial_ind).Preparation_Time = Preparation_Time(trial_num(trial_ind));
    trials(trial_ind).Previous_Error = Previous_Error{trial_num(trial_ind)};
    trials(trial_ind).Test_Stimulus = Test_Stimulus{trial_num(trial_ind)};
    trials(trial_ind).Rule_Cues = Rule_Cues{trial_num(trial_ind)};
    trials(trial_ind).Rule_Cue_Repetition = Rule_Cue_Repetition{trial_num(trial_ind)};
    trials(trial_ind).Incorrect = Incorrect{trial_num(trial_ind)};
    
    for neuron_ind = 1:numNeurons,
        cur_spikes = spikes(cur_trial, neuron_ind);
        cur_spikes(isnan(cur_spikes)) = 0;
        cur_time = trial_time(cur_trial);
        neuron_name = sprintf('%s_%d_%d', cur_file, wire_number(neuron_ind), unit_number(neuron_ind));
        trials(trial_ind).(neuron_name) = cur_time(logical(cur_spikes));    
    end
    
end

data2json.neurons = neurons;
data2json.trials = trials;

cur_json = savejson(cur_file, data2json);
cd(save_dir);
fid = fopen([cur_file, '.json'], 'w');
fprintf(fid, cur_json);
fclose(fid);
