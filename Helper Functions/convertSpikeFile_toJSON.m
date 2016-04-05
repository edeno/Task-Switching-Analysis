function convertSpikeFile_toJSON(sessionName, saveDir)
% Load Common Parameters
workingDir = getWorkingDir();
sessionFile = sprintf('%s/Processed Data/Entire Trial/SpikeCov/%s_SpikeCov.mat', workingDir, sessionName);
behaviorFile = sprintf('%s/Behavior/behavior.mat', workingDir);
paramSetFile = sprintf('%s/paramSet.mat', workingDir);
load(sessionFile);
load(behaviorFile);
load(paramSetFile);

behavior = behavior{ismember(sessionNames, sessionName)};

monkeyName = unique(behavior('Monkey'));
area_names = {'ACC', 'dlPFC'};

trialNum = unique(trialID);
numTrials = length(trialNum);

isIncluded = behavior('Attempted') & behavior('Correct');

behavior('Correct') = behavior('Correct') + 1;
behavior('Fixation Break') = behavior('Fixation Break') + 1;
behavior('Included') = isIncluded + 1;

s.levels = {'Incorrect', 'Correct', };
s.isCategorical = true;
covInfo('Correct') = s;

s.levels = {'Fixation Break', 'No Fixation Break'};
s.isCategorical = true;
covInfo('Fixation Break') = s;

s.levels = {'Excluded', 'Included'};
s.isCategorical = true;
covInfo('Included') = s;

s.levels = {'1 ms'};
s.isCategorical = false;
covInfo('Reaction Time') = s;

covNames = {'Rule', 'Response Direction', 'Previous Error', 'Test Stimulus', ...
    'Rule Cues', 'Rule Cue Switch', 'Rule Repetition', 'Included', 'Correct', ...
    'Fixation Break', 'Preparation Time', 'Congruency', 'Reaction Time'};
cov = cell(size(covNames));

for n = 1:length(covNames),
    cov{n} = convertCov(covNames{n}, covInfo, behavior);
end

fixOn_time = behavior('Intertrial Interval Time');
ruleOn_time = fixOn_time + behavior('Fixation Accquired Time') + behavior('Fixation Time'); % Fix spot on + fix spot accquired + fixation time
stimOn_time = ruleOn_time + behavior('Preparation Time');
react_time = stimOn_time + behavior('Reaction Time');
reward_time = react_time + behavior('Saccade Fixation Time');

fixBreaks = behavior('Fixation Break');

parfor trial_ind = 1:numTrials,
    cur_trial = ismember(trialID, trialNum(trial_ind));
    trials(trial_ind).trial_id = trialNum(trial_ind);
    
    if fixBreaks(trialNum(trial_ind))== 1 && ~isnan(react_time(trialNum(trial_ind))),
        trials(trial_ind).start_time = min(trialTime(cur_trial));
        trials(trial_ind).fixation_onset = fixOn_time(trialNum(trial_ind));
        trials(trial_ind).rule_onset = ruleOn_time(trialNum(trial_ind));
        trials(trial_ind).stim_onset = stimOn_time(trialNum(trial_ind));
        trials(trial_ind).react_time = react_time(trialNum(trial_ind));
        trials(trial_ind).reward_time = reward_time(trialNum(trial_ind));
        trials(trial_ind).end_time = max(trialTime(cur_trial));
    else
        trials(trial_ind).start_time = NaN;
        trials(trial_ind).fixation_onset = NaN;
        trials(trial_ind).rule_onset = NaN;
        trials(trial_ind).stim_onset = NaN;
        trials(trial_ind).react_time = NaN;
        trials(trial_ind).reward_time = NaN;
        trials(trial_ind).end_time = NaN;
    end
    
    trials(trial_ind).Rule = cov{ismember(covNames, 'Rule')}{trialNum(trial_ind)};
    trials(trial_ind).Rule_Repetition = cov{ismember(covNames, 'Rule Repetition')}{trialNum(trial_ind)};
    trials(trial_ind).Response_Direction = cov{ismember(covNames, 'Response Direction')}{trialNum(trial_ind)};
    trials(trial_ind).Congruency = cov{ismember(covNames, 'Congruency')}{trialNum(trial_ind)};
    trials(trial_ind).Preparation_Time = cov{ismember(covNames, 'Preparation Time')}(trialNum(trial_ind));
    trials(trial_ind).Previous_Error = cov{ismember(covNames, 'Previous Error')}{trialNum(trial_ind)};
    trials(trial_ind).Test_Stimulus = cov{ismember(covNames, 'Test Stimulus')}{trialNum(trial_ind)};
    trials(trial_ind).Rule_Cues = cov{ismember(covNames, 'Rule Cues')}{trialNum(trial_ind)};
    trials(trial_ind).Rule_Cue_Repetition = cov{ismember(covNames, 'Rule Cue Switch')}{trialNum(trial_ind)};
    trials(trial_ind).isCorrect = cov{ismember(covNames, 'Correct')}{trialNum(trial_ind)};
    trials(trial_ind).isIncluded = cov{ismember(covNames, 'Included')}{trialNum(trial_ind)};
    trials(trial_ind).Fixation_Break = cov{ismember(covNames, 'Fixation Break')}{trialNum(trial_ind)};
    trials(trial_ind).Reaction_Time = cov{ismember(covNames, 'Reaction Time')}(trialNum(trial_ind));
    
end


opt.FileName = [sessionName, '_TrialInfo.json'];
opt.NaN = 'null';

cd(saveDir);
savejson('', trials, opt);

%%

for neuron_ind = 1:numNeurons,
    neuron = struct(...
        'Name', sprintf('%s_%d_%d', sessionName, wire_number(neuron_ind), unit_number(neuron_ind)), ...
        'Brain_Area', neuronBrainArea(neuron_ind), ...
        'Subject', monkeyName, ...
        'Recording_Session', sessionName);
    
    for trial_ind = 1:numTrials,
        cur_trial = ismember(trialID, trialNum(trial_ind));
        neuron.Spikes(trial_ind).trialID = trialNum(trial_ind);
        
        cur_spikes = spikes(cur_trial, neuron_ind);
        cur_spikes(isnan(cur_spikes)) = 0;
        cur_time = trialTime(cur_trial);
        if ~behavior.Fixation_Break(trialNum(trial_ind)) && ~isnan(react_time(trialNum(trial_ind))),
            spike_times = cur_time(logical(cur_spikes))';
            if length(spike_times) == 1,
                % Stupid hack to force the spikes to be an array.
                neuron.Spikes(trial_ind).spikes = [spike_times spike_times];
            else
                neuron.Spikes(trial_ind).spikes = spike_times;
            end
        else
            neuron.Spikes(trial_ind).spikes = [];
        end
    end
    
    opt.FileName = ['Neuron_', neuron.Name,'.json'];
    savejson('', neuron, opt);
    
    clear neuron
end
end

function [cov] = convertCov(covName, covInfo, behavior)
covIndex = behavior(covName);

% Handle NaN conditions - Set NaN to 1, then fix later
isNaN_cond = isnan(behavior('Condition'));
covIndex(isNaN_cond) = 1;
if covInfo(covName).isCategorical,
    cov = covInfo(covName).levels(behavior(covName))';
    cov(isNaN_cond) = {NaN};
else
    cov = behavior(covName)';
    cov(isNaN_cond) = NaN;
end

end