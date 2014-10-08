function [apc] = apcPlot_process2(apc_type, isNormalized, valid_models, monkey, baseline_bounds)
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
mean_covAPC = cell(numTimePeriods, numCov, 2, 3);
ci_covAPC =  cell(numTimePeriods, numCov, 2, 3, 2);
mean_ruleByAPC = cell(numTimePeriods, numCov, 2, 3);
ci_ruleByAPC = cell(numTimePeriods, numCov, 2, 3, 2);

norm_apc = @(apc, baseline_firing)  ...
    apc ./ repmat(baseline_firing, [size(apc, 1) 1 1]);

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
        
        ruleAPC_file = load(sprintf('%s/%s/Collected/apc_collected.mat', apc_dir, 'Rule'));
        % Some things to sort or filter by
        pfc = logical([ruleAPC_file.avpred.pfc]);
        monkey_names_ind = upper({ruleAPC_file.avpred.monkey});
        baseline_firing = squeeze([ruleAPC_file.avpred.baseline_firing])';
        baseline_firing = reshape(baseline_firing, [1 size(baseline_firing, 1) size(baseline_firing, 2)]);
        
        brain_area = brain_area_ind-1;
        
        % Figure out which neurons to ignore
        filter_ind = (pfc == brain_area) & ...
            ismember(monkey_names_ind, monkey);
        
        % Filter those neurons out
        ruleAPC = cat(3, ruleAPC_file.avpred.apc);
        ruleAPC = ruleAPC(:,:, filter_ind);
        baseline_firing = baseline_firing(:, :, filter_ind);
        if isNormalized,
            ruleAPC = norm_apc(ruleAPC, baseline_firing);
        end
        
        rule_quant_bounds = squeeze(quantile(ruleAPC, [0 1/3 2/3 1], 3));
        rule_quant_id = bsxfun(@le, squeeze(ruleAPC), rule_quant_bounds(:, 2)) + 3*bsxfun(@gt, squeeze(ruleAPC), rule_quant_bounds(:, 3));
        rule_quant_id(rule_quant_id == 0) = 2;
        
        % Loop over covariates
        for cov_ind = find(ismember(valid_covariates, apcs)),
            if ismember(valid_covariates{cov_ind}, 'Rule'),
                continue;
            end
            fprintf('\t Covariate: %s\n', valid_covariates{cov_ind});
            
            [mean_covAPC_temp, ci_covAPC_temp, mean_ruleByAPC_temp, ci_ruleByAPC_temp] = ...
                populationChange(apc_dir, valid_covariates{cov_ind}, apc_type, brain_area, monkey, baseline_firing, baseline_bounds, isNormalized, rule_quant_id);
            
            [mean_covAPC{time_ind, cov_ind, brain_area_ind, :}] = deal(mean_covAPC_temp{:});
            [ci_covAPC{time_ind, cov_ind, brain_area_ind, :, :}] = deal(ci_covAPC_temp{:});
            [mean_ruleByAPC{time_ind, cov_ind, brain_area_ind, :}] = deal(mean_ruleByAPC_temp{:});
            [ci_ruleByAPC{time_ind, cov_ind, brain_area_ind, :, :}]= deal(ci_ruleByAPC_temp{:});
        end
        
    end
end
%% Fill empty cells with NaNs
for cov_ind = 1:numCov,
    % covAPC
    empty_ind = cellfun(@isempty, mean_covAPC(:, cov_ind, 1, 1));
    if all(empty_ind),
        [mean_covAPC{empty_ind, cov_ind, :, :}] = deal(NaN);
        [ci_covAPC{empty_ind, cov_ind, :, :, :, :}] = deal(NaN);
        
    else
        nans = nan(size(mean_covAPC{find(~empty_ind, 1), cov_ind}));
        [mean_covAPC{empty_ind, cov_ind, :, :}] = deal(nans);
        [ci_covAPC{empty_ind, cov_ind, :, :, :}] = deal(nans);
    end
    
    % ruleByAPC
    empty_ind = cellfun(@isempty, mean_ruleByAPC(:, cov_ind, 1, 1));
    if all(empty_ind),
        [mean_ruleByAPC{empty_ind, cov_ind, :, :}] = deal(NaN);
        [ci_ruleByAPC{empty_ind, cov_ind, :, :, :}] = deal(NaN);
    else
        nans = nan(size(mean_ruleByAPC{find(~empty_ind, 1), cov_ind}));
        [mean_ruleByAPC{empty_ind, cov_ind, :, :}] = deal(nans);
        [ci_ruleByAPC{empty_ind, cov_ind, :, :, :}] = deal(nans);
    end
    
end

%% Place Previous Congruency in Congruency History
con_hist_ind = ismember(valid_covariates, 'Congruency History');
prev_con_ind = ismember(valid_covariates, 'Previous Congruency');

for time_ind = 1:numTimePeriods,
    for ci_ind = 1:2,
        for brain_area_ind = 1:2,
            for rule_ind = 1:3,
                if isnan(mean_covAPC{time_ind, con_hist_ind, brain_area_ind, rule_ind}(1)),
                    mean_covAPC{time_ind, con_hist_ind, brain_area_ind, rule_ind}(1) = mean_covAPC{time_ind, prev_con_ind, brain_area_ind, rule_ind};
                end
                if isnan(ci_covAPC{time_ind, con_hist_ind, brain_area_ind, rule_ind, ci_ind}(1)),
                    ci_covAPC{time_ind, con_hist_ind, brain_area_ind, rule_ind, ci_ind}(1) = ci_covAPC{time_ind, prev_con_ind, brain_area_ind, rule_ind, ci_ind};
                end
                
                if all(isnan(mean_ruleByAPC{time_ind, con_hist_ind, brain_area_ind, rule_ind}(1:2))),
                    mean_ruleByAPC{time_ind, con_hist_ind, brain_area_ind, rule_ind}(1:2) = mean_ruleByAPC{time_ind, prev_con_ind, brain_area_ind, rule_ind};
                end
                if all(isnan(ci_ruleByAPC{time_ind, con_hist_ind, brain_area_ind, rule_ind, ci_ind}(1:2))),
                    ci_ruleByAPC{time_ind, con_hist_ind, brain_area_ind, rule_ind, ci_ind}(1:2) = ci_ruleByAPC{time_ind, prev_con_ind, brain_area_ind, rule_ind, ci_ind};
                end
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
function [mean_covAPC, ci_covAPC, mean_ruleByAPC, ci_ruleByAPC] = populationChange(apc_dir, curCov, apc_type, brain_area, monkey, baseline_firing, baseline_bounds, isNormalized, rule_quant_id)

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

baseline_ind = squeeze((baseline_firing < baseline_bounds(1)) | (baseline_firing > baseline_bounds(1)));

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

mean_covAPC = cell(3, 1);
mean_ruleByAPC = cell(3, 1);
ci_covAPC = cell(3, 2);
ci_ruleByAPC  = cell(3, 2);

% Calculate Statistics
for rule_id = 1:3,
    filtered_covAPC = rule_filter(covAPC, rule_id, baseline_ind, rule_quant_id);
    filtered_ruleByAPC = rule_filter(ruleByAPC, rule_id, baseline_ind, rule_quant_id);
    
    if isNormalized,
        mean_covAPC{rule_id} = mean_norm_apc(filtered_covAPC, baseline_firing);
        mean_ruleByAPC{rule_id} = mean_norm_apc(filtered_ruleByAPC, baseline_firing);
        
        ci_covAPC{rule_id, 1} = ci_lower_norm_apc(filtered_covAPC, baseline_firing);
        ci_ruleByAPC{rule_id, 1} = ci_lower_norm_apc(filtered_ruleByAPC, baseline_firing);
        
        ci_covAPC{rule_id, 2} = ci_upper_norm_apc(filtered_covAPC, baseline_firing);
        ci_ruleByAPC{rule_id, 2} = ci_upper_norm_apc(filtered_ruleByAPC, baseline_firing);
    else
        mean_covAPC{rule_id} = mean_apc(filtered_covAPC);
        mean_ruleByAPC{rule_id} = mean_apc(filtered_ruleByAPC);
        
        ci_covAPC{rule_id, 1} = ci_lower_apc(filtered_covAPC);
        ci_ruleByAPC{rule_id, 1} = ci_lower_apc(filtered_ruleByAPC);
        
        ci_covAPC{rule_id, 2} = ci_upper_apc(filtered_covAPC);
        ci_ruleByAPC{rule_id, 2} = ci_upper_apc(filtered_ruleByAPC);
    end
end

end

function [apc] = rule_filter(apc, id, baseline_ind, rule_quant_id)

filter_ind = double((baseline_ind) & (rule_quant_id == id));
filter_ind(filter_ind == 0) = NaN;
filter_ind = reshape(filter_ind, [1, size(filter_ind, 1), size(filter_ind, 2)]);
filter_ind = repmat(filter_ind, [size(apc, 1), 1, 1]);

apc = filter_ind .* apc;

end