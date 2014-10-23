function [apc, timePeriods] = apcPlot_process3(apc_type, isNormalized, valid_models)
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
apc = cell(numTimePeriods, 1);

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
    apc_names = dir(apc_dir);
    apc_names = {apc_names.name};
    apc_names(ismember(apc_names, {'.', '..'})) = [];
    
    ruleAPC_file = load(sprintf('%s/%s/Collected/apc_collected.mat', apc_dir, 'Rule'));
    numNeurons = length(ruleAPC_file.avpred);
    parfor neuron_ind = 1:numNeurons,
        neuron_name = sprintf('%s_%d_%d', ruleAPC_file.avpred(neuron_ind).session_name, ruleAPC_file.avpred(neuron_ind).wire_number, ruleAPC_file.avpred(neuron_ind).unit_number);
        neurons(neuron_ind)= struct(...
            'Name', neuron_name, ...
            'Brain_Area', brain_area_names{ruleAPC_file.avpred(neuron_ind).pfc+1}, ...
            'Monkey', upper(ruleAPC_file.avpred(neuron_ind).monkey), ...
            'File_Name', ruleAPC_file.avpred(neuron_ind).session_name, ...
            'Average_Firing_Rate',  mean(ruleAPC_file.avpred(neuron_ind).baseline_firing(:)), ...
            'Overall_Rule', mean(ruleAPC_file.avpred(neuron_ind).(apc_type), 2), ...
            'Overall_Rule_CI', quantile(ruleAPC_file.avpred(neuron_ind).(apc_type), [.025 .975], 2) ...
            );
    end
    
    
    % Loop over covariates
    for cov_ind = find(ismember(valid_covariates, apc_names)),
        curCov = valid_covariates{cov_ind};
        if ismember(curCov, 'Rule'),
            continue;
        end
        
        fprintf('\t Covariate: %s\n', curCov);
        %% Load Files
        % Load RuleBy files if they exists
        try
            ruleByAPC_file = load(sprintf('%s/RuleBy_%s/Collected/apc_collected.mat', apc_dir, curCov));
        catch
            continue;
        end
        
        byLevels = ruleByAPC_file.avpred(1).by_levels;
        byLevels = regexprep(byLevels, ' ', '_');
        byLevels = regexprep(byLevels, '+', 'plus');
        byLevels = regexprep(byLevels, '-', 'minus');
        try
            byLevels{strcmp(byLevels, '1_Std_Dev_of_Prep_Time')} = 'plus1_Std_Dev_of_Prep_Time';
        end
        parfor neuron_ind = 1:numNeurons,
            cur_apc_est = mean(ruleByAPC_file.avpred(neuron_ind).(apc_type), 2);
            cur_apc_ci = quantile(ruleByAPC_file.avpred(neuron_ind).(apc_type), [.025 .975], 2);
            
            for by_ind = 1:length(byLevels),
                by_name = byLevels{by_ind};
                
                neurons(neuron_ind).(by_name) = cur_apc_est(by_ind);
                neurons(neuron_ind).([by_name '_CI']) = cur_apc_ci(by_ind, :);
            end
        end
        
        
    end
    apc{time_ind} = neurons;
    clear neurons
end


end
