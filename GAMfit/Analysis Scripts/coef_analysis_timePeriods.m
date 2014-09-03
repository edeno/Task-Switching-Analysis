clear all; close all; clc;
%% Create anonymouse functions that give the population mean and standard deviation
mean_pop = @(stat, filter_ind) mean(mean(stat(:, :, filter_ind), 3), 1);
ci_pop = @(stat, filter_ind) quantile(mean(stat(:, :, filter_ind), 3), [.025 .975], 1);

std_pop = @(stat, filter_ind) mean(std(stat(:, :, filter_ind), [], 3), 1);
std_ci_pop = @(stat, filter_ind) quantile(std(stat(:, :, filter_ind), [], 3), [.025 .975], 1);

mult_change = @(x) exp(x);
pct_change = @(x) (x - 1) * 100;
%%
drop_dir = getappdata(0, 'drop_path');
data_dir = [drop_dir, '/GAM Analysis/Previous Error History Indicator'];
cd(data_dir);

timePeriods = {'Intertrial Interval', 'Fixation', 'Rule Stimulus', ...
    'Stimulus Response', 'Saccade', 'Reward'};

for time_ind = 1:length(timePeriods),
    cd(timePeriods{1});
    
    %% Load and Prepare Data
    cur_file = load('neurons.mat');
    pfc = logical([cur_file.neurons.pfc]);
    numSim = size(cur_file.neurons(1).par_sim, 1);
    numLevels = length(cur_file.gam.level_names);
    numNeurons = length(cur_file.neurons);
    par_sim = [cur_file.neurons.par_sim];
    par_sim = reshape(par_sim, [numSim, numLevels, numNeurons]);
    
    level_names = cur_file.gam.level_names;
    cov_names = cur_file.gam.cov_names;
    cov_names = regexp(cov_names, ':', 'split');
    
    isRuleCov = cellfun(@(x) any(ismember(x, 'Rule')), cov_names);
    isInteractionCov = cellfun(@(x) length(x) > 1, cov_names);  
    
    
    %% Back to main data directory
    cd(data_dir);
end