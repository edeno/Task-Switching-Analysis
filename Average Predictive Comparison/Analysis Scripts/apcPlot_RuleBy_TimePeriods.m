function apcPlot_RuleBy_TimePeriods()
%% Set Parameters
main_dir = '/data/home/edeno/Task Switching Analysis';
brain_area_name = 'ACC';
isNormalized = true;
apc_type = 'abs_apc';
monkey = 'All';
baseline_bounds = [];

valid_models = {'Rule * Switch History + Rule * Previous Error History + Rule * Previous Congruency', ...
    'Rule * Switch History + Rule * Previous Error History + Rule * Congruency History + Response Direction + Rule * Normalized Prep Time'};

valid_covariates = cellfun(@(x) strtrim(regexp(x, '+|*', 'split')), valid_models, 'UniformOutput', false);
valid_covariates = unique([valid_covariates{:}]);
numCov = length(valid_covariates);

% Load time period names
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

% Preallocate
mean_covAPC = cell(numTimePeriods, numCov);
ci_covAPC =  cell(numTimePeriods, numCov, 2);
mean_ruleByAPC = cell(numTimePeriods, numCov);
ci_ruleByAPC = cell(numTimePeriods, numCov, 2);

%% Collect Data
fprintf('Processing....');
% Loop Over Time Periods
for time_ind = 1:numTimePeriods,
    fprintf('\n Time Period: %s\n', timePeriods{time_ind});
    % Which Model?
    models_dir = [main_dir, '/Processed Data/', timePeriods{time_ind}, '/Models'];
    model = dir(models_dir);
    model = {model.name};
    model(ismember(model, {'.', '..'})) = [];
    model = model(ismember(model, valid_models));
    
    % Get all the APCs
    apc_dir = [models_dir, '/', model{:}, '/APC/'];
    apcs = dir(apc_dir);
    apcs = {apcs.name};
    apcs(ismember(apcs, {'.', '..'})) = [];
    
    % Loop over covariates
    for cov_ind = find(ismember(valid_covariates, apcs)),
        fprintf('\t Covariate: %s\n', valid_covariates{cov_ind});
        [mean_covAPC_temp, ci_covAPC_temp, mean_ruleByAPC_temp, ci_ruleByAPC_temp] = ...
            populationChange(apc_dir, valid_covariates{cov_ind}, apc_type, brain_area, monkey, baseline_bounds, isNormalized);
        
        mean_covAPC{time_ind, cov_ind} = mean_covAPC_temp{:};
        [ci_covAPC{time_ind, cov_ind, :}] = deal(ci_covAPC_temp{:});
        mean_ruleByAPC{time_ind, cov_ind} = mean_ruleByAPC_temp{:};
        [ci_ruleByAPC{time_ind, cov_ind, :}]= deal(ci_ruleByAPC_temp{:});
    end
    
end

%% Plot

end


%% ------------------------------------------------------------------------
function [mean_covAPC, ci_covAPC, mean_ruleByAPC, ci_ruleByAPC] = populationChange(apc_dir, curCov, apc_type, brain_area, monkey, baseline_bounds, isNormalized)

% Statistical helper functions
mean_apc = @(apc) nanmean(nanmean(apc, 3), 2);
ci_lower_apc = @(apc) quantile(nanmean(apc, 3), .025, 2);
ci_upper_apc = @(apc) quantile(nanmean(apc, 3), .975, 2);

norm_apc = @(apc, baseline_firing)  ...
    apc ./ shiftdim(repmat(baseline_firing', [1, size(apc, 1), size(apc, 2)]), 1);

mean_norm_apc = @(apc, baseline_firing) ...
    mean_apc(norm_apc(apc, baseline_firing));
ci_lower_norm_apc = @(apc, baseline_firing) ...
    ci_lower_apc(norm_apc(apc, baseline_firing));
ci_upper_norm_apc = @(apc, baseline_firing) ...
    ci_upper_apc(norm_apc(apc, baseline_firing));

%% Load Files
covAPC_file = load(sprintf('%s/%s/Collected/apc_collected.mat', apc_dir, curCov));
% Load RuleBy files if they exists
try
    ruleByAPC_file = load(sprintf('%s/RuleBy_%s/Collected/apc_collected.mat', apc_dir, curCov));
catch
    ruleByAPC_file = [];
end

% Some things to sort or filter by
pfc = logical([covAPC_file.avpred.pfc]);
monkey_names_ind = upper({covAPC_file.avpred.monkey});
baseline_firing = [covAPC_file.avpred.baseline_firing];

numSamples = covAPC_file.avpred(1).numSamples;
numSim = covAPC_file.avpred(1).numSim;

% Figure out which neurons to ignore
filter_ind = (pfc == brain_area) & ...
    ismember(monkey_names_ind, monkey) & ...
    (baseline_firing > baseline_bounds(1)) & ...
    (baseline_firing < baseline_bounds(2));

% Filter those neurons out
covAPC = cat(3, covAPC_file.avpred.(apc_type));
if isempty(ruleByAPC_file),
    ruleByAPC = nan(size(covAPC));
else
    ruleByAPC = cat(3, ruleByAPC_file.avpred.(apc_type));
end

covAPC = covAPC(:,:, filter_ind);
baseline_firing = baseline_firing(filter_ind);
ruleByAPC = ruleByAPC(:,:, filter_ind);

% Calculate Statistics
if isNormalized,
    mean_covAPC{1} = mean_norm_apc(covAPC, baseline_firing);
    mean_ruleByAPC{1} = mean_norm_apc(ruleByAPC, baseline_firing);
    
    ci_covAPC{1} = ci_lower_norm_apc(covAPC, baseline_firing);
    ci_ruleByAPC{1} = ci_lower_norm_apc(ruleByAPC, baseline_firing);
    
    ci_covAPC{2} = ci_upper_norm_apc(covAPC, baseline_firing);
    ci_ruleByAPC{2} = ci_upper_norm_apc(ruleByAPC, baseline_firing);
else
    mean_covAPC{1} = mean_apc(covAPC);
    mean_ruleByAPC{1} = mean_apc(ruleByAPC);
    
    ci_covAPC{1} = ci_lower_apc(covAPC);
    ci_ruleByAPC{1} = ci_lower_apc(ruleByAPC);
    
    ci_covAPC{2} = ci_upper_apc(covAPC);
    ci_ruleByAPC{2} = ci_upper_apc(ruleByAPC);
end

end