clear variables; close all; clc;
main_dir = getWorkingDir();
load([main_dir, 'paramSet.mat'], ...
    'sessionNames', 'monkeyNames', 'dataInfo');

%%
count = 1;
for subject_ind = 1:length(monkeyNames),
    curSessions = regexp(sessionNames, [lower(monkeyNames{subject_ind}),'.*'], 'match');
    curSessions = [curSessions{:}];
    for session_ind = 1:length(curSessions),
        curSessionFile = sprintf('%s/Raw Data/%s.sdt', main_dir, curSessions{session_ind});
        curSessionFile = load(curSessionFile, '-mat', 'cells');
        for neuron_ind = 1:length(curSessionFile.cells),
            neuronName = sprintf('%s_%d_%d', ...
                curSessions{session_ind}, ...
                curSessionFile.cells(neuron_ind).WireNumber, ...
                curSessionFile.cells(neuron_ind).UnitNumber);
            
            trialInfo.neurons(count).name = neuronName;
            trialInfo.neurons(count).sessionName = curSessions{session_ind};
            trialInfo.neurons(count).subjectName = monkeyNames{subject_ind};
            if curSessionFile.cells(neuron_ind).WireNumber > 8 && ~strcmp('isa5', curSessions{session_ind});
                trialInfo.neurons(count).brainArea = 'ACC';
            else
                if strcmp('isa5', curSessions{session_ind}) && curSessionFile.cells(neuron_ind).WireNumber > 16
                    trialInfo.neurons(count).brainArea = 'ACC';
                else
                    trialInfo.neurons(count).brainArea = 'dlPFC';
                end
            end
            count = count + 1;
        end
    end
end

%%

trialInfo.timePeriods(1).name = 'Intertrial Interval';
trialInfo.timePeriods(1).label = '<br>ITI';
trialInfo.timePeriods(1).startID = 'start_time';
trialInfo.timePeriods(1).endID = 'fixation_onset';
trialInfo.timePeriods(1).color = '#c5b0d5';

trialInfo.timePeriods(2).name = 'Fixation Cue';
trialInfo.timePeriods(2).label = '<br>Fix.';
trialInfo.timePeriods(2).startID = 'fixation_onset';
trialInfo.timePeriods(2).endID = 'rule_onset';
trialInfo.timePeriods(2).color = '#f7b6d2';

trialInfo.timePeriods(3).name = 'Rule Cue';
trialInfo.timePeriods(3).label = '<br>Rule';
trialInfo.timePeriods(3).startID = 'rule_onset';
trialInfo.timePeriods(3).endID = 'stim_onset';
trialInfo.timePeriods(3).color = '#98df8a';

trialInfo.timePeriods(4).name = 'Test Stimulus Cue';
trialInfo.timePeriods(4).label = 'Test<br>Stimulus';
trialInfo.timePeriods(4).startID = 'stim_onset';
trialInfo.timePeriods(4).endID = 'react_time';
trialInfo.timePeriods(4).color = '#ff9896';

trialInfo.timePeriods(5).name = 'Saccade';
trialInfo.timePeriods(5).label = '<br>Saccade';
trialInfo.timePeriods(5).startID = 'react_time';
trialInfo.timePeriods(5).endID = 'reward_time';
trialInfo.timePeriods(5).color = '#9edae5';

trialInfo.timePeriods(6).name = 'Start Reward';
trialInfo.timePeriods(6).label = '<br>Reward';
trialInfo.timePeriods(6).startID = 'reward_time';
trialInfo.timePeriods(6).endID = 'end_time';
trialInfo.timePeriods(6).color = '#c49c94';

%%
trialInfo.experimentalFactor(1).name = 'Trial ID';
trialInfo.experimentalFactor(1).factorType = 'continuous';
trialInfo.experimentalFactor(1).value = 'trial_id';

trialInfo.experimentalFactor(2).name = 'Rule (Color vs. Orientation)';
trialInfo.experimentalFactor(2).factorType = 'categorical';
trialInfo.experimentalFactor(2).value = 'Rule';

trialInfo.experimentalFactor(3).name = 'Error on Previous Trial';
trialInfo.experimentalFactor(3).factorType = 'categorical';
trialInfo.experimentalFactor(3).value = 'Previous_Error';

trialInfo.experimentalFactor(4).name = 'Number of Rule Repetitions (# of trials)';
trialInfo.experimentalFactor(4).factorType = 'ordinal';
trialInfo.experimentalFactor(4).value = 'Rule_Repetition';

trialInfo.experimentalFactor(5).name = 'Congruency';
trialInfo.experimentalFactor(5).factorType = 'categorical';
trialInfo.experimentalFactor(5).value = 'Congruency';

trialInfo.experimentalFactor(6).name = 'Preparation Time before Stimulus Onset (ms)';
trialInfo.experimentalFactor(6).factorType = 'continuous';
trialInfo.experimentalFactor(6).value = 'Preparation_Time';

trialInfo.experimentalFactor(7).name = 'Response Direction (Left vs. Right Saccade)';
trialInfo.experimentalFactor(7).factorType = 'categorical';
trialInfo.experimentalFactor(7).value = 'Response_Direction';

trialInfo.experimentalFactor(8).name = 'Response Time (ms)';
trialInfo.experimentalFactor(8).factorType = 'continuous';
trialInfo.experimentalFactor(8).value = 'Reaction_Time';

trialInfo.experimentalFactor(9).name = 'Test Stimulus Cue';
trialInfo.experimentalFactor(9).factorType = 'categorical';
trialInfo.experimentalFactor(9).value = 'Test_Stimulus';

trialInfo.experimentalFactor(10).name = 'Rule Cues';
trialInfo.experimentalFactor(10).factorType = 'categorical';
trialInfo.experimentalFactor(10).value = 'Rule_Cues';

trialInfo.experimentalFactor(11).name = 'Rule Cue Repetition';
trialInfo.experimentalFactor(11).factorType = 'ordinal';
trialInfo.experimentalFactor(11).value = 'Rule_Cue_Repetition';

trialInfo.experimentalFactor(12).name = 'Correct/Incorrect';
trialInfo.experimentalFactor(12).factorType = 'categorical';
trialInfo.experimentalFactor(12).value = 'isCorrect';
%%
save_dir = sprintf('%sFigures/Entire Trial/', main_dir);
opt.FileName = 'trialInfo.json';
opt.NaN = 'null';

cd(save_dir);
savejson('', trialInfo, opt);