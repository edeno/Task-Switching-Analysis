%% RuleBy APC
clear all; clc;

%% Parameters
curCov = 'Previous Error History Indicator';
brain_area_name = 'ACC';
main_dir = '/data/home/edeno/Task Switching Analysis';
isPreviousErrorIndicator = true;
isNormalized = true;
apc_type = 'apc';
monkey = 'All';
baseline_bounds = [];

%% Load time period names
load([main_dir, '/paramSet.mat'], 'validFolders', 'monkey_names');
timePeriods = validFolders(~ismember(validFolders, 'Rule Response'));
numTimePeriods = length(timePeriods);

%% Setup Filtering variables
% Monkey
if strcmp(monkey, 'All'),
    monkey = upper(monkey_names);
end
% Brain Area
if strcmp(brain_area_name, 'dlPFC'),
    brain_area = true;
else
    brain_area = false;
end
% Baseline Firing Bounds
if isempty(baseline_bounds),
    baseline_bounds = [0 1000];
end

% Statistical helper functions
mean_apc = @(apc, filter_ind) nanmean(nanmean(apc(:,:, filter_ind), 3), 2);
ci_lower_apc = @(apc, filter_ind) quantile(nanmean(apc(:,:, filter_ind), 3), .025, 2);
ci_upper_apc = @(apc, filter_ind) quantile(nanmean(apc(:,:, filter_ind), 3), .975, 2);

norm_apc = @(apc, filter_ind, baseline_firing)  ...
    apc(:,:, filter_ind) ./ ...
    shiftdim(repmat(baseline_firing(filter_ind)', [1, size(apc(:,:, filter_ind), 1), size(apc(:,:, filter_ind), 2)]), 1);

mean_norm_apc = @(apc, filter_ind, baseline_firing) ...
    nanmean(nanmean(norm_apc(apc, filter_ind, baseline_firing), 3), 2);
ci_lower_norm_apc = @(apc, filter_ind, baseline_firing) ...
    quantile(nanmean(norm_apc(apc, filter_ind, baseline_firing), 3), .025, 2);
ci_upper_norm_apc = @(apc, filter_ind, baseline_firing) ...
    quantile(nanmean(norm_apc(apc, filter_ind, baseline_firing), 3), .975, 2);

% Preallocate
mean_ruleAPC = cell(numTimePeriods, 1);
mean_covAPC = cell(numTimePeriods, 1);
mean_ruleByAPC = cell(numTimePeriods, 1);

ci_ruleAPC = cell(numTimePeriods , 2);
ci_covAPC = cell(numTimePeriods , 2);
ci_ruleByAPC = cell(numTimePeriods , 2);

%% Loop over the time periods
for time_ind = 1:numTimePeriods ,
    models_dir = [main_dir, '/Processed Data/', timePeriods{time_ind}, '/Models'];
    model = dir(models_dir);
    model = {model.name};
    model(ismember(model, {'.', '..'})) = [];
    isIndicator = cellfun(@(x) ~isempty(strfind(x, 'Indicator')), model);
    
    % Which Model?
    if isPreviousErrorIndicator,
        model = model(isIndicator);
    else
        model = model(~isIndicator);
    end
    
    apc_dir = [models_dir, '/', model{:}, '/APC'];
    
    ruleAPC = load(sprintf('%s/Rule/Collected/apc_collected.mat', apc_dir));
    covAPC = load(sprintf('%s/%s/Collected/apc_collected.mat', apc_dir, curCov));
    ruleByAPC = load(sprintf('%s/RuleBy_%s/Collected/apc_collected.mat', apc_dir, curCov));
    
    % Some things to sort or filter by
    pfc = logical([ruleAPC.avpred.pfc]);
    monkey_names_ind = upper({ruleAPC.avpred.monkey});
    baseline_firing = [ruleAPC.avpred.baseline_firing];
    
    numSamples = ruleAPC.avpred(1).numSamples;
    numSim = ruleAPC.avpred(1).numSim;
    by_levels = ruleByAPC.avpred(1).by_levels;
    
    % Extract APC
    ruleAPC = cat(3, ruleAPC.avpred.(apc_type));
    covAPC = cat(3, covAPC.avpred.(apc_type));
    ruleByAPC = cat(3, ruleByAPC.avpred.(apc_type));
    
    filter_ind = (pfc == brain_area) & ...
        ismember(monkey_names_ind, monkey) & ...
        (baseline_firing > baseline_bounds(1)) & ...
        (baseline_firing < baseline_bounds(2));
    
    % Calculate Statistics
    if isNormalized,
        mean_ruleAPC{time_ind} = mean_norm_apc(ruleAPC, filter_ind, baseline_firing);
        mean_covAPC{time_ind} = mean_norm_apc(covAPC, filter_ind, baseline_firing);
        mean_ruleByAPC{time_ind} = mean_norm_apc(ruleByAPC, filter_ind, baseline_firing);
        
        ci_ruleAPC{time_ind, 1} = ci_lower_norm_apc(ruleAPC, filter_ind, baseline_firing);
        ci_covAPC{time_ind, 1} = ci_lower_norm_apc(covAPC, filter_ind, baseline_firing);
        ci_ruleByAPC{time_ind, 1} = ci_lower_norm_apc(ruleByAPC, filter_ind, baseline_firing);
        
        ci_ruleAPC{time_ind, 2} = ci_upper_norm_apc(ruleAPC, filter_ind, baseline_firing);
        ci_covAPC{time_ind, 2} = ci_upper_norm_apc(covAPC, filter_ind, baseline_firing);
        ci_ruleByAPC{time_ind, 2} = ci_upper_norm_apc(ruleByAPC, filter_ind, baseline_firing);
    else
        mean_ruleAPC{time_ind} = mean_apc(ruleAPC, filter_ind);
        mean_covAPC{time_ind} = mean_apc(covAPC, filter_ind);
        mean_ruleByAPC{time_ind} = mean_apc(ruleByAPC, filter_ind);
        
        ci_ruleAPC{time_ind, 1} = ci_lower_apc(ruleAPC, filter_ind);
        ci_covAPC{time_ind, 1} = ci_lower_apc(covAPC, filter_ind);
        ci_ruleByAPC{time_ind, 1} = ci_lower_apc(ruleByAPC, filter_ind);
        
        ci_ruleAPC{time_ind, 2} = ci_upper_apc(ruleAPC, filter_ind);
        ci_covAPC{time_ind, 2} = ci_upper_apc(covAPC, filter_ind);
        ci_ruleByAPC{time_ind, 2} = ci_upper_apc(ruleByAPC, filter_ind);
    end
    
end

%% Plotting
colororder = [
    0.00  0.00  1.00
    0.00  0.50  0.00
    1.00  0.00  0.00
    0.00  0.75  0.75
    0.75  0.00  0.75
    0.75  0.75  0.00
    0.25  0.25  0.25
    0.75  0.25  0.25
    0.95  0.95  0.00
    0.25  0.25  0.75
    0.75  0.75  0.75
    0.00  1.00  0.00
    0.76  0.57  0.17
    0.54  0.63  0.22
    0.34  0.57  0.92
    1.00  0.10  0.60
    0.88  0.75  0.73
    0.10  0.49  0.47
    0.66  0.34  0.65
    0.99  0.41  0.23
    ];

mean_ruleByAPC = cat(2, mean_ruleByAPC{:});
mean_ruleAPC = cat(2, mean_ruleAPC{:});
mean_covAPC = cat(2, mean_covAPC{:});

figure;
if ismember(curCov, {'Previous Error History', 'Congruency History'}),
    isLowLevel = cellfun(@(x) ~isempty(x), strfind(by_levels, 'No')) | ...
        cellfun(@(x) ~isempty(x), strfind(by_levels, 'Congruent'));
    
    subplot(3,3,[2:3 5:6])
    plot(mean_ruleByAPC(~isLowLevel, :))
    legend(timePeriods)
    box off;
else
    subplot(3,3,[2:3 5:6])
    plot(mean_ruleByAPC)
    legend(timePeriods)
    box off;
    
end

subplot(3,3, [1 4]);
% r = 0.999 + (1.001-0.999).*rand(numTimePeriods,1); % Jitter scatter plot for readability
r = ones(numTimePeriods, 1);
scatter(r, mean_ruleAPC, 100, colororder(1:numTimePeriods,:), 'filled')
xlim([0.95 1.05]);
box off;

subplot(3,3, [8 9]);
plot(mean_covAPC)
box off;

suptitle(sprintf('%s: %s', brain_area_name, curCov));
