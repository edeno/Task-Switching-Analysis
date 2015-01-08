%% Setup Data Parameters
clear all; close all; clc;

% Define main data directory
data_info.main_dir = '/data/home/edeno/Task Switching Analysis';

% Make main
if ~exist(data_info.main_dir, 'dir')
    mkdir(data_info.main_dir);
end

% Define sub-directories
data_info.script_dir = sprintf('%s/Matlab Scripts', data_info.main_dir);
data_info.processed_dir = sprintf('%s/Processed Data', data_info.main_dir);
data_info.behavior_dir = sprintf('%s/Behavior', data_info.main_dir);
data_info.manuscript_dir = sprintf('%s/Manuscript', data_info.main_dir);
data_info.figure_dir = sprintf('%s/Figures', data_info.main_dir);
data_info.rawData_dir = sprintf('%s/Raw Data', data_info.main_dir);

% Make sub-directories
data_fieldNames = fieldnames(data_info);
for data_ind = 1:length(data_fieldNames),
    if ~exist(data_info.(data_fieldNames{data_ind}), 'dir'),
        mkdir(data_info.(data_fieldNames{data_ind}));
    end
end

%% Setup Encode Parameters

% Trial Time Parameters
trial_info.Start_encode = 9;
trial_info.FixationOn_encode = 35;
trial_info.FixationAccquired_encode = 8;
trial_info.RuleOn_encode = 29;
trial_info.SampleOn_encode = 23;
trial_info.SaccadeStart_encode = 44;
trial_info.SaccadeFixation_encode = 45;
trial_info.Reward_encode = 4;
trial_info.noReward_encode = 5;
trial_info.RewardStart_encode = {trial_info.Reward_encode, trial_info.noReward_encode};
trial_info.End_encode = 18;

% Condition Parameters
trial_info.Rule_color = [0:7 16:23];
trial_info.Rule_orientation = [8:15 24:31];
trial_info.Rule_color1 = [0 1 4 5 16 17 20 21]; %16 6 Cue4.bmp 26 x 36 Black sq
trial_info.Rule_color2 = [2 3 6 7 18 19 22 23]; %6 Only 26 x 36 black sq
trial_info.Rule_orient1 = [8 9 12 13 24 25 28 29]; %15 6 Cue3.bmp(w/black)
trial_info.Rule_orient2 = [10 11 14 15 26 27 30 31]; %5 6 37 x 49 Pink Sq 26 x 36 Black sq
trial_info.Stimulus_vertBlue = [16 18 24 26 20 22 28 30];
trial_info.Stimulus_vertRed = [0 2 8 10 4 6 12 14];
trial_info.Stimulus_horzBlue = [1 3 9 11 5 7 13 15];
trial_info.Stimulus_horzRed = [17 19 25 27 21 23 29 31];
trial_info.Saccade_right = [0 9 2 11 4 13 6 15 17 25 19 27 21 29 23 31];
trial_info.Saccade_left = [1 3 5 7 8 10 12 14 16 18 20 22 24 26 28 30];
trial_info.Correct = 0;
trial_info.Incorrect = 6;
trial_info.FixationBreak = [3 4];

monkey_names = {'CC', 'CH', 'ISA'};

%% Save Everything

save_file_name = sprintf('%s/paramSet.mat', data_info.main_dir);
save(save_file_name, '*_info', 'monkey_names');
