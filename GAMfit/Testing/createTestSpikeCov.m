function [spikeCov_name, timePeriodDir, session_name] = createTestSpikeCov(mainDir, numTrials)

% Create paramSet file
processedDir = [mainDir, '/Processed Data'];
if ~exist(processedDir, 'dir'),
    mkdir(processedDir);
end
save([mainDir, '/paramSet.mat'], 'processedDir');

% Create Folders
timePeriod = 'Testing';
session_name = 'test';

timePeriodDir = [processedDir, '/', timePeriod];
modelsDir = [timePeriodDir, '/Models'];
spikeCov_dir = [timePeriodDir, '/spikeCov'];

if ~exist(timePeriodDir, 'dir'),
    mkdir(timePeriodDir);
end
if ~exist(modelsDir, 'dir'),
    mkdir(modelsDir);
end
if ~exist(spikeCov_dir, 'dir'),
    mkdir(spikeCov_dir);
end

% Create spikeCov
[spikeCov, trialID, trialTime, incorrect] = simSession(numTrials);

numNeurons = 1;
wire_number = 1;
unit_number = 1;
neuronBrainArea = {'Test'};
percentTrials = ones(size(trialTime));

% Save spikeCov
spikeCov_name = [spikeCov_dir, '/', session_name, '_SpikeCov.mat'];
save(spikeCov_name, ...
    'spikeCov', 'trialID', 'trialTime', 'incorrect', 'wire_number', ...
    'unit_number', 'neuronBrainArea', 'percent_trials', 'numNeurons');
end