function [apc] = apcPlot_process(apc_type, isNormalized, valid_models, monkey, baseline_bounds)
%% Set Parameters
main_dir = '/data/home/edeno/Task Switching Analysis';

valid_covariates = cellfun(@(x) strtrim(regexp(x, '+|*', 'split')), valid_models, 'UniformOutput', false);
valid_covariates = unique([valid_covariates{:}]);
numCov = length(valid_covariates);

% Load time period names
load([main_dir, '/paramSet.mat'], 'validFolders', 'monkey_names');
timePeriods = validFolders(~ismember(validFolders, 'Rule Response'));
numTimePeriods = length(timePeriods);

brain_area_names = {'ACC', 'dlPFC'};

%% Setup Filtering variables
% Monkey
if strcmp(monkey, 'All'),
    monkey = upper(monkey_names);
end

% Baseline Firing Bounds
if isempty(baseline_bounds),
    baseline_bounds = [0 1000];
end

% Preallocate
mean_covAPC = cell(numTimePeriods, numCov, 2);
ci_covAPC =  cell(numTimePeriods, numCov, 2, 2);
mean_ruleByAPC = cell(numTimePeriods, numCov, 2);
ci_ruleByAPC = cell(numTimePeriods, numCov, 2, 2);

%% Collect Data
fprintf('Processing....');
% Loop Over Time Periods
for brain_area_ind = 1:2,
    fprintf('\n Brain Area: %s\n', brain_area_names{brain_area_ind});
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
                populationChange(apc_dir, valid_covariates{cov_ind}, apc_type, brain_area_ind-1, monkey, baseline_bounds, isNormalized);
            
            [mean_covAPC{time_ind, cov_ind, brain_area_ind}] = deal(mean_covAPC_temp{:});
            [ci_covAPC{time_ind, cov_ind, :, brain_area_ind}] = deal(ci_covAPC_temp{:});
            [mean_ruleByAPC{time_ind, cov_ind, brain_area_ind}] = deal(mean_ruleByAPC_temp{:});
            [ci_ruleByAPC{time_ind, cov_ind, :, brain_area_ind}]= deal(ci_ruleByAPC_temp{:});
        end
        
    end
end
%% Fill empty cells with NaNs
for cov_ind = 1:numCov,
    % covAPC
    empty_ind = cellfun(@isempty, mean_covAPC(:, cov_ind, 1));
    if all(empty_ind),
        [mean_covAPC{empty_ind, cov_ind, :}] = deal(NaN);
        [ci_covAPC{empty_ind, cov_ind, :, :}] = deal(NaN);
        
    else
        nans = nan(size(mean_covAPC{find(~empty_ind, 1), cov_ind}));
        [mean_covAPC{empty_ind, cov_ind, :}] = deal(nans);
        [ci_covAPC{empty_ind, cov_ind, :}] = deal(nans);
    end
    
    % ruleByAPC
    empty_ind = cellfun(@isempty, mean_ruleByAPC(:, cov_ind, 1));
    if all(empty_ind),
        [mean_ruleByAPC{empty_ind, cov_ind, :}] = deal(NaN);
        [ci_ruleByAPC{empty_ind, cov_ind, :, :}] = deal(NaN);
    else
        nans = nan(size(mean_ruleByAPC{find(~empty_ind, 1), cov_ind}));
        [mean_ruleByAPC{empty_ind, cov_ind, :}] = deal(nans);
        [ci_ruleByAPC{empty_ind, cov_ind, :, :}] = deal(nans);
    end
    
end

%% Place Previous Congruency in Congruency History
con_hist_ind = ismember(valid_covariates, 'Congruency History');
prev_con_ind = ismember(valid_covariates, 'Previous Congruency');

for time_ind = 1:numTimePeriods,
    for ci_ind = 1:2,
        for brain_area_ind = 1:2,
            
            if isnan(mean_covAPC{time_ind, con_hist_ind, brain_area_ind}(1)),
                mean_covAPC{time_ind, con_hist_ind, brain_area_ind}(1) = mean_covAPC{time_ind, prev_con_ind, brain_area_ind};
            end
            if isnan(ci_covAPC{time_ind, con_hist_ind, ci_ind, brain_area_ind}(1)),
                ci_covAPC{time_ind, con_hist_ind, ci_ind, brain_area_ind}(1) = ci_covAPC{time_ind, prev_con_ind, ci_ind, brain_area_ind};
            end
            
            if all(isnan(mean_ruleByAPC{time_ind, con_hist_ind, brain_area_ind}(1:2))),
                mean_ruleByAPC{time_ind, con_hist_ind, brain_area_ind}(1:2) = mean_ruleByAPC{time_ind, prev_con_ind, brain_area_ind};
            end
            if all(isnan(ci_ruleByAPC{time_ind, con_hist_ind, ci_ind, brain_area_ind}(1:2))),
                ci_ruleByAPC{time_ind, con_hist_ind, ci_ind, brain_area_ind}(1:2) = ci_ruleByAPC{time_ind, prev_con_ind, ci_ind, brain_area_ind};
            end
            
        end
    end
    
end



%% Save to structure
apc.mean_covAPC = mean_covAPC;
apc.ci_covAPC = ci_covAPC;
apc.mean_ruleByAPC = mean_ruleByAPC;
apc.ci_ruleByAPC = ci_ruleByAPC;
apc.valid_covariates = valid_covariates;
apc.timePeriods = timePeriods;
apc.brain_area_names = brain_area_names;
apc.apc_type = apc_type;
apc.isNormalized = isNormalized;
apc.valid_models = valid_models;
apc.monkey = monkey;
apc.baseline_bounds = baseline_bounds;

end


%% ------------------------------------------------------------------------
function [mean_covAPC, ci_covAPC, mean_ruleByAPC, ci_ruleByAPC] = populationChange(apc_dir, curCov, apc_type, brain_area, monkey, baseline_bounds, isNormalized)


%% Load Files
covAPC_file = load(sprintf('%s/%s/Collected/apc_collected.mat', apc_dir, curCov));
% Load RuleBy files if they exists
try
    ruleByAPC_file = load(sprintf('%s/RuleBy_%s/Collected/apc_collected.mat', apc_dir, curCov));
catch
    ruleByAPC_file = [];
end

% Temporary 
b = load(sprintf('%s/%s/Collected/apc_collected.mat', apc_dir, 'Rule'));

% Some things to sort or filter by
pfc = logical([covAPC_file.avpred.pfc]);
monkey_names_ind = upper({covAPC_file.avpred.monkey});
baseline_firing = squeeze([b.avpred.baseline_firing])';
baseline_firing = reshape(baseline_firing, [1 size(baseline_firing, 1) size(baseline_firing, 2)]);

numSamples = covAPC_file.avpred(1).numSamples;
numSim = covAPC_file.avpred(1).numSim;

% Statistical helper functions
mean_apc = @(apc) nanmean(nanmean(apc, 3), 2);
ci_lower_apc = @(apc) quantile(nanmean(apc, 3), .025, 2);
ci_upper_apc = @(apc) quantile(nanmean(apc, 3), .975, 2);

norm_apc = @(apc, baseline_firing)  ...
    apc ./ repmat(baseline_firing, [size(apc, 1), 1, 1]);

mean_norm_apc = @(apc, baseline_firing) ...
    mean_apc(norm_apc(apc, baseline_firing));
ci_lower_norm_apc = @(apc, baseline_firing) ...
    ci_lower_apc(norm_apc(apc, baseline_firing));
ci_upper_norm_apc = @(apc, baseline_firing) ...
    ci_upper_apc(norm_apc(apc, baseline_firing));

% Figure out which neurons to ignore
filter_ind = (pfc == brain_area) & ...
    ismember(monkey_names_ind, monkey);

% Filter those neurons out
covAPC = cat(3, covAPC_file.avpred.(apc_type));

if isempty(ruleByAPC_file),
    ruleByAPC = nan(size(covAPC));
else
    ruleByAPC = cat(3, ruleByAPC_file.avpred.(apc_type));
end

covAPC = covAPC(:,:, filter_ind);
ruleByAPC = ruleByAPC(:,:, filter_ind);
baseline_firing = baseline_firing(:, :, filter_ind);

baseline_ind = (baseline_firing > baseline_bounds(1)) & ...
    (baseline_firing < baseline_bounds(2));
baseline_ind = double(baseline_ind);
baseline_ind(baseline_ind == 0) = NaN;

covAPC = covAPC .* repmat(baseline_ind, [size(covAPC, 1), 1, 1]);
ruleByAPC = ruleByAPC .* repmat(baseline_ind, [size(ruleByAPC, 1), 1, 1]);

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