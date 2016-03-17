% Simulate Session
numTrials = 3000;
[spikeCov, trial_time, isCorrect, isAttempted, trial_id] = simSession(numTrials);

% Load Common Parameters
mainDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', mainDir), 'covInfo');
% Binary Categorical Covariate - Rule
trueRate = nan(size(trial_time));

cov_id = @(cov_name, level_name) find(ismember(covInfo(cov_name).levels, level_name));
level_ind = @(cov_name, level_name) ismember(spikeCov(cov_name), cov_id(cov_name, level_name));

colorRate = 10;
orientRate = 5;
trueRate(level_ind('Rule', 'Color')) = colorRate;
trueRate(level_ind('Rule', 'Orientation')) = orientRate;

timePeriod = 'Testing';
sessionName = 'test';
timePeriodDir = sprintf('%s/Processed Data/%s/', mainDir, timePeriod);
dt = 1E-3;
spikes = simPoisson(trueRate, dt);
% Append spikes to GLMCov file
% Save Simulated Session
SpikeCovName = sprintf('%s/SpikeCov/test_SpikeCov.mat', timePeriodDir);
save(SpikeCovName, 'spikes', '-append');

load(SpikeCovName);

%%
reactionTime = behavior('Reaction Time');
preparationTime = behavior('Preparation Time');
Rule = spikeCov('Rule');
ruleRepetition = spikeCov('Rule Repetition');
responseDirection = spikeCov('Response Direction');
correctLevels = {'Incorrect', 'Correct'};

numTrials = max(trialID);

neuron(1).Name = sprintf('%s_%d_%d', sessionName, wire_number, unit_number);

for trial_ind = 1:numTrials,
    curTrial = ismember(trialID, trial_ind);
    trials(trial_ind).trial_id = trial_ind;
    
    trials(trial_ind).start_time = min(trialTime(curTrial));
    trials(trial_ind).stim_onset = preparationTime(trial_ind);
    trials(trial_ind).react_time = reactionTime(trial_ind);
    trials(trial_ind).end_time = max(trialTime(curTrial));
    
    trials(trial_ind).Rule = covInfo('Rule').levels(unique(Rule(curTrial)));
    trials(trial_ind).Rule_Repetition = covInfo('Rule Repetition').levels(unique(ruleRepetition(curTrial)));
    trials(trial_ind).Response_Direction = covInfo('Response Direction').levels(unique(responseDirection(curTrial)));
    trials(trial_ind).Preparation_Time = preparationTime(trial_ind);
    trials(trial_ind).isCorrect = correctLevels{unique(isCorrect(curTrial) + 1)};
    trials(trial_ind).isIncluded = 'Included';
    trials(trial_ind).Fixation_Break = 'No Fixation Break';
    trials(trial_ind).Reaction_Time = reactionTime(trial_ind);
    neuron.Spikes(trial_ind).trial_id = trial_ind;
    curTime = trialTime(curTrial);
    neuron.Spikes(trial_ind).spikes = curTime(logical(spikes(curTrial)));
end

%%
trialInfo.neurons(1).name = neuron(1).Name;
trialInfo.neurons(1).sessionName = sessionName;
trialInfo.neurons(1).subjectName = 'test';
trialInfo.neurons(1).brainArea = 'testArea';

trialInfo.timePeriods(1).name = 'Rule Cue';
trialInfo.timePeriods(1).label = '<br>Rule';
trialInfo.timePeriods(1).startID = 'start_time';
trialInfo.timePeriods(1).endID = 'stim_onset';
trialInfo.timePeriods(1).color = '#98df8a';

trialInfo.timePeriods(2).name = 'Test Stimulus Cue';
trialInfo.timePeriods(2).label = 'Test<br>Stimulus';
trialInfo.timePeriods(2).startID = 'stim_onset';
trialInfo.timePeriods(2).endID = 'react_time';
trialInfo.timePeriods(2).color = '#ff9896';

trialInfo.experimentalFactor(1).name = 'Trial ID';
trialInfo.experimentalFactor(1).factorType = 'continuous';
trialInfo.experimentalFactor(1).value = 'trial_id';

trialInfo.experimentalFactor(2).name = 'Rule (Color vs. Orientation)';
trialInfo.experimentalFactor(2).factorType = 'categorical';
trialInfo.experimentalFactor(2).value = 'Rule';

trialInfo.experimentalFactor(3).name = 'Number of Rule Repetitions (# of trials)';
trialInfo.experimentalFactor(3).factorType = 'ordinal';
trialInfo.experimentalFactor(3).value = 'Rule_Repetition';

trialInfo.experimentalFactor(4).name = 'Preparation Time before Stimulus Onset (ms)';
trialInfo.experimentalFactor(4).factorType = 'continuous';
trialInfo.experimentalFactor(4).value = 'Preparation_Time';

trialInfo.experimentalFactor(5).name = 'Response Direction (Left vs. Right Saccade)';
trialInfo.experimentalFactor(5).factorType = 'categorical';
trialInfo.experimentalFactor(5).value = 'Response_Direction';

trialInfo.experimentalFactor(6).name = 'Response Time (ms)';
trialInfo.experimentalFactor(6).factorType = 'continuous';
trialInfo.experimentalFactor(6).value = 'Reaction_Time';

trialInfo.experimentalFactor(7).name = 'Correct/Incorrect';
trialInfo.experimentalFactor(7).factorType = 'categorical';
trialInfo.experimentalFactor(7).value = 'isCorrect';

%%
workingDir = getWorkingDir();
saveDir = sprintf('%s/Figures/Test/Visualization Data/', workingDir);
if ~exist(saveDir, 'dir'),
    mkdir(saveDir);
end
opt.FileName = [sessionName, '_TrialInfo.json'];
opt.NaN = 'null';

cd(saveDir);
savejson('', trials, opt);

opt.FileName = ['Neuron_', neuron.Name,'.json'];
savejson('', neuron, opt);

opt.FileName = 'trialInfo.json';
opt.NaN = 'null';

savejson('', trialInfo, opt);