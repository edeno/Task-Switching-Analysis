function apcToJSON(apc_type, valid_models)
%% Set Parameters
main_dir = '/data/home/edeno/Task Switching Analysis';

valid_covariates = cellfun(@(x) strtrim(regexp(x, '+|*', 'split')), valid_models, 'UniformOutput', false);
valid_covariates = unique([valid_covariates{:}]);

% Load time period names
load([main_dir, '/paramSet.mat'], 'validFolders', 'monkey_names');
timePeriods = validFolders(~ismember(validFolders, {'Rule Response', 'Entire Trial'}));
numTimePeriods = length(timePeriods);

brain_area_names = {'ACC', 'dlPFC'};

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
    avpred = struct2table(ruleAPC_file.avpred);
    
    avpred.Brain_Area = brain_area_names(avpred.pfc+1)';
    avpred.pfc = [];
    avpred.Monkey = upper(avpred.monkey);
    avpred.monkey = [];
    avpred.numSim = [];
    avpred.numSamples = [];
    avpred.Average_Firing_Rate = cellfun(@(x) sprintf('%.2f', x), num2cell(mean(avpred.baseline_firing, 3)), 'UniformOutput', false);
    avpred.baseline_firing = [];
    avpred.Overall = cellfun(@(x) sprintf('%.2f', x), num2cell(mean(avpred.(apc_type), 2)), 'UniformOutput', false);
    avpred.norm_apc = [];
    avpred.abs_apc = [];
    avpred.apc = [];
    avpred.model_name = [];
    
    avpred.Properties.RowNames = cellfun(@(x,y,z) sprintf('%s_%s_%s', x, num2str(y), num2str(z)), ...
        avpred.session_name, num2cell(avpred.wire_number), num2cell(avpred.unit_number), ...
        'UniformOutput', false);
    avpred.Properties.DimensionNames = {'Name', 'Variable'};
    avpred.Properties.VariableNames{'session_name'} = 'Session_Name';
    avpred.Properties.VariableNames{'wire_number'} = 'Wire_Number';
    avpred.Properties.VariableNames{'unit_number'} = 'Unit_Number';
    
    % Loop over covariates
    for cov_ind = find(ismember(valid_covariates, apc_names)),
        curCov = valid_covariates{cov_ind};
        if ismember(curCov, 'Rule'),
            continue;
        end
        fprintf('\t Covariate: %s\n', curCov);
        %% Load Files
        % Load files if they exists
        try
            apc_file = load(sprintf('%s/%s/Collected/apc_collected.mat', apc_dir, curCov));
        catch
            continue;
        end
        
        temp_table =  struct2table(apc_file.avpred);
        
        levels = apc_file.avpred(1).levels;
        levels = regexprep(levels, ' ', '_');
        levels = regexprep(levels, '+', 'plus');
        levels = regexprep(levels, '-', 'minus');
        try
            levels{strcmp(levels, '1_Std_Dev_of_Prep_Time')} = 'plus1_Std_Dev_of_Prep_Time';
        end
        
        for level_ind = 1:length(levels),
            dat = cellfun(@(x) mean(x(level_ind, :), 2), temp_table.(apc_type), 'UniformOutput', false);
            dat = cellfun(@(x) sprintf('%.2f', x), dat, 'UniformOutput', false);
            avpred.(levels{level_ind}) = dat;
        end
        
        
        
    end
    
    table_name = sprintf('%s/%s %s main effects.csv', main_dir, timePeriods{time_ind}, apc_type);
    writetable(avpred, table_name, 'writeRowNames', true, 'Delimiter', ',');
    clear avpred temp_table;
end

