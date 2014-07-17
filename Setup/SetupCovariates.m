%% Setup Covariates
clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';

%% Define Covariates
cov_info(1).name = 'Prep Time';
cov_info(1).levels = {'1 ms of prep time'};
cov_info(1).isCategorical = false;

cov_info(2).name = 'Rule';
cov_info(2).levels = {'Orientation', 'Color'};
cov_info(2).isCategorical = true;

cov_info(3).name = 'Switch';
cov_info(3).levels = {'Repetition', 'Switch'};
cov_info(3).isCategorical = true;

cov_info(4).name = 'Congruency';
cov_info(4).levels = {'Congruent', 'Incongruent'};
cov_info(4).isCategorical = true;

cov_info(5).name = 'Test Stimulus';
cov_info(5).levels = {'Vertical Blue', 'Vertical Red', 'Horizontal Blue', 'Horizontal Red'};
cov_info(5).isCategorical = true;

cov_info(6).name = 'Rule Cues';
cov_info(6).levels = {'Color Cue1', 'Color Cue2', 'Orientation Cue1', 'Orientation Cue2'};
cov_info(6).isCategorical = true;

cov_info(7).name = 'Rule Cue Switch';
cov_info(7).levels = {'Repetition', 'Switch'};
cov_info(7).isCategorical = true;

cov_info(8).name = 'Test Stimulus Color';
cov_info(8).levels = {'Blue', 'Red'};
cov_info(8).isCategorical = true;

cov_info(9).name = 'Test Stimulus Orientation';
cov_info(9).levels = {'Vertical', 'Horizontal'};
cov_info(9).isCategorical = true;

cov_info(10).name = 'Normalized Prep Time';
cov_info(10).levels = {'1 Std Dev of Prep Time'};
cov_info(10).isCategorical = false;

cov_info(11).name = 'Response Direction';
cov_info(11).levels = {'Right', 'Left'};
cov_info(11).isCategorical = true;

cov_info(12).name = 'Previous Error';
cov_info(12).levels = {'No Previous Error', 'Previous Error'};
cov_info(12).isCategorical = true;

cov_info(13).name = 'Previous Error History';
error_hist_names = [strseq('No Previous Error', 1:10) strseq('Previous Error', 1:10)]';
cov_info(13).levels = error_hist_names(:);
cov_info(13).isCategorical = true;

cov_info(14).name = 'Switch History';
switch_hist_names = [strseq('Repetition', 1:10); 'Repetition11+']';
cov_info(14).levels = switch_hist_names;
cov_info(14).isCategorical = true;

cov_info(15).name = 'Trial Time';
cov_info(15).levels = {'Time'};
cov_info(15).isCategorical = false;

cov_info(16).name = 'Switch Distance';
cov_info(16).levels = {'1 Trial'};
cov_info(16).isCategorical = false;

cov_info(17).name = 'Error Distance';
cov_info(17).levels = {'1 Trial'};
cov_info(17).isCategorical = false;

cov_info(18).name = 'Congruency History';
cov_info(18).levels = {'Congruent', 'Incongruent', 'Previous Congruent', 'Previous Incongruent'};
cov_info(18).isCategorical = true;

cov_info(19).name = 'Indicator Prep Time';
cov_info(19).levels = {'Short', 'Medium', 'Long'};
cov_info(19).isCategorical = true;

cov_info(20).name = 'Previous Congruency';
cov_info(20).levels = {'Previous Congruent', 'Previous Incongruent'};
cov_info(20).isCategorical = true;

cov_info(21).name = 'Spike History';
spike_names = [strseq('No Previous Spike', 1:125) strseq('Previous Spike', 1:125)]';
cov_info(21).levels = spike_names(:);
cov_info(21).isCategorical = true;

cov_info(22).name = 'Previous Error History Indicator';
error_hist_names = [strseq('Previous Error', 1:10); 'Previous Error11+']';
cov_info(22).levels = error_hist_names;
cov_info(22).isCategorical = true;

validCov = {cov_info.name};

%% Append Information to ParamSet
save_file_name = sprintf('%s/paramSet.mat', main_dir);
save(save_file_name, 'cov_info', '-append');