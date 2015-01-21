function convertFile_toJSON(session_name, save_dir)
% Load Common Parameters
load('paramSet.mat', 'data_info');
load([data_info.processed_dir, '/Entire Trial/', session_name, '_GLMCov.mat']);
load([data_info.behavior_dir, '/', 'behavior.mat']);

behavior = behavior(ismember({behavior.session_name}, session_name));
isIncluded = behavior.attempted;

area_names = {'ACC', 'dlPFC'};
monkey_name = unique(behavior.monkey);

trial_num = unique(trial_id);
numTrials = length(trial_num);

for neuron_ind = 1:numNeurons,
    neurons(neuron_ind)= struct(...
        'Name', sprintf('%s_%d_%d', session_name, wire_number(neuron_ind), unit_number(neuron_ind)), ...
        'Brain_Area', area_names{pfc(neuron_ind)+1}, ...
        'Monkey', monkey_name, ...
        'File_Name', session_name, ...
        'Number_of_Trials', numTrials);
end

rule_levels = GLMCov(ismember({GLMCov.name}, 'Rule')).levels;
responseDir_levels = GLMCov(ismember({GLMCov.name}, 'Response Direction')).levels;
previousError_levels = GLMCov(ismember({GLMCov.name}, 'Previous Error')).levels;
congruencyHistory_levels = GLMCov(ismember({GLMCov.name}, 'Congruency History')).levels;
testStimulus_levels = GLMCov(ismember({GLMCov.name}, 'Test Stimulus')).levels;
ruleCue_levels = GLMCov(ismember({GLMCov.name}, 'Rule Cues')).levels;
ruleCueRepetition_levels = GLMCov(ismember({GLMCov.name}, 'Rule Cue Switch')).levels;
isCorrect_levels = {'Incorrect', 'Correct', };
isIncluded_levels = {'Excluded', 'Included'};
fixationBreak_levels = {'No Fixation Break', 'Fixation Break'};

behavior.Previous_Error(isnan(behavior.Previous_Error)) = 1;
behavior.Congruency_History(isnan(behavior.Congruency_History)) = 1;

Rule = rule_levels(behavior.Rule)';
Preparation_Time = behavior.Prep_Time;
Response_Direction = responseDir_levels(behavior.Response_Direction)';
Previous_Error = previousError_levels(behavior.Previous_Error)';
Congruency_History = congruencyHistory_levels(behavior.Congruency_History);
Current_Congruency = Congruency_History(:,1);
Previous_Congruency = Congruency_History(:,2);
Test_Stimulus = testStimulus_levels(behavior.Test_Stimulus)';
Rule_Cues = ruleCue_levels(behavior.Rule_Cues)';
Rule_Cue_Repetition = ruleCueRepetition_levels(behavior.Rule_Cue_Switch)';
Rule_Repetition = behavior.Switch_History;
isCorrect = isCorrect_levels(behavior.correct + 1)';
isIncluded = isIncluded_levels(isIncluded + 1)';
fixationBreak = fixationBreak_levels(behavior.Fixation_Break + 1)';

fixOn_time = behavior.ITI_Time;
ruleOn_time = fixOn_time + behavior.fixOn_time + behavior.Fix_Time; % Fix spot on + fix spot accquired + fixation time
stimOn_time = ruleOn_time + behavior.Prep_Time;
react_time = stimOn_time + behavior.Reaction_Time;
reward_time = react_time + behavior.Saccade_Time;

parfor trial_ind = 1:numTrials,
    
    cur_trial = ismember(trial_id, trial_num(trial_ind));
    trials(trial_ind).trial_id = trial_num(trial_ind);
    
    if ~behavior.Fixation_Break(trial_num(trial_ind)),
        trials(trial_ind).start_time = 1;
        trials(trial_ind).fixation_onset = fixOn_time(trial_num(trial_ind));
        trials(trial_ind).rule_onset = ruleOn_time(trial_num(trial_ind));
        trials(trial_ind).stim_onset = stimOn_time(trial_num(trial_ind));
        trials(trial_ind).react_time = react_time(trial_num(trial_ind));
        trials(trial_ind).reward_time = reward_time(trial_num(trial_ind));
        trials(trial_ind).end_time = max(trial_time(cur_trial));
    else
        trials(trial_ind).start_time = NaN;
        trials(trial_ind).fixation_onset = NaN;
        trials(trial_ind).rule_onset = NaN;
        trials(trial_ind).stim_onset = NaN;
        trials(trial_ind).react_time = NaN;
        trials(trial_ind).reward_time = NaN;
        trials(trial_ind).end_time = NaN;
    end
    
    
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
    trials(trial_ind).isCorrect = isCorrect{trial_num(trial_ind)};
    trials(trial_ind).isIncluded = isIncluded{trial_num(trial_ind)};
    trials(trial_ind).Fixation_Break = fixationBreak{trial_num(trial_ind)};
    trials(trial_ind).Reaction_Time = behavior.Reaction_Time(trial_num(trial_ind));
    
    for neuron_ind = 1:numNeurons,
        cur_spikes = spikes(cur_trial, neuron_ind);
        cur_spikes(isnan(cur_spikes)) = 0;
        cur_time = trial_time(cur_trial);
        neuron_name = sprintf('%s_%d_%d', session_name, wire_number(neuron_ind), unit_number(neuron_ind));
        if ~behavior.Fixation_Break(trial_num(trial_ind)),
            trials(trial_ind).(neuron_name) = cur_time(logical(cur_spikes));
        else
            trials(trial_ind).(neuron_name) = [];
        end
    end
    
end

data2json.neurons = neurons;
data2json.trials = trials;

opt.FileName = [session_name, '.json'];
opt.NaN = 'null';

cd(save_dir);
cur_json = savejson(session_name, data2json, opt);
end
