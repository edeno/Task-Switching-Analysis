function [GLMCov_name, timePeriod_dir, session_name] = create_testGLMCov(main_dir, numTrials)

% Create paramSet file
data_info.processed_dir = [main_dir, '/Processed Data'];
if ~exist(data_info.processed_dir, 'dir'),
    mkdir(data_info.processed_dir);
end
save([main_dir, '/paramSet.mat'], 'data_info');

% Create Folders
timePeriod = 'timePeriod';
session_name = 'cc';

timePeriod_dir = [data_info.processed_dir, '/', timePeriod];
models_dir = [timePeriod_dir, '/Models'];
GLMCov_dir = [timePeriod_dir, '/GLMCov'];

if ~exist(timePeriod_dir, 'dir'),
    mkdir(timePeriod_dir);
end
if ~exist(models_dir, 'dir'),
    mkdir(models_dir);
end
if ~exist(GLMCov_dir, 'dir'),
    mkdir(GLMCov_dir);
end

% Create GLMCov
[GLMCov, trial_id, trial_time, incorrect] = simSession(numTrials);

numNeurons = 1;
wire_number = 1;
unit_number = 1;
pfc = true;
sample_on = ones(size(trial_time));
percent_trials = ones(size(trial_time));

% Save GLMCov
GLMCov_name = [GLMCov_dir, '/', session_name, '_GLMCov.mat'];
save(GLMCov_name, ...
    'GLMCov', 'trial_id', 'trial_time', 'incorrect', 'wire_number', ...
    'unit_number', 'pfc', 'sample_on', 'percent_trials', 'numNeurons');
end