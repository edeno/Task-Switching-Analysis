function apcTimeToJSON(apc_type, valid_models)
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
    if time_ind == 1,
        numNeurons = length(ruleAPC_file.avpred);
        apc(numNeurons).Name = [];
        
        Name = cellfun(@(x,y,z) sprintf('%s_%s_%s', x, num2str(y), num2str(z)), ...
            {ruleAPC_file.avpred.session_name}, num2cell([ruleAPC_file.avpred.wire_number]), num2cell([ruleAPC_file.avpred.unit_number]), ...
            'UniformOutput', false);
        [apc.Name] = deal(Name{:});
        [apc.Brain_Area] = deal(brain_area_names{[ruleAPC_file.avpred.pfc]+1});
        monkey = cellfun(@upper, {ruleAPC_file.avpred.monkey}, 'UniformOutput', false);
        [apc.Monkey] = deal(monkey{:});
        [apc.Session_Name] = deal(ruleAPC_file.avpred.session_name);
        wire_number = cellfun(@(x) sprintf('%s', num2str(x)), num2cell([ruleAPC_file.avpred.wire_number]), 'UniformOutput', false);
        [apc.Wire_Number] = deal(wire_number{:});
        unit_number = cellfun(@(x) sprintf('%s', num2str(x)), num2cell([ruleAPC_file.avpred.unit_number]), 'UniformOutput', false);
        [apc.Unit_Number] = deal(unit_number{:});
        
    end
    avgFiring{time_ind} = [ruleAPC_file.avpred.baseline_firing];
    avgFiring_mean = mean(avgFiring{time_ind}, 3);
    avgFiring_mean(avgFiring_mean > 1E3 | avgFiring_mean < 1E-3) = 0;
    for neuron_ind = 1:numNeurons,
        [apc(neuron_ind).Average_Firing_Rate(1, time_ind)] = avgFiring_mean(neuron_ind);
    end
    
    % Loop over covariates
    for cov_ind = find(ismember(valid_covariates, apc_names)),
        curCov = valid_covariates{cov_ind};
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
        
        cov_apc = temp_table.(apc_type);
        if ~isa(cov_apc, 'cell'),
            cov_apc = num2cell(temp_table.(apc_type), 2);
        end
        
        for level_ind = 1:length(levels),
            dat = cellfun(@(x) mean(x(level_ind, :), 2), cov_apc, 'UniformOutput', false);
            %             dat = cellfun(@(x) sprintf('%.2f', x), dat, 'UniformOutput', false);
            for neuron_ind = 1:numNeurons,
                [apc(neuron_ind).(levels{level_ind})(1, time_ind)] = dat{neuron_ind};
            end
        end
        
    end
    
end

overall_avgFiring = cat(1, avgFiring{:});
overall_avgFiring = mean(mean(overall_avgFiring, 1), 3);
for neuron_ind = 1:numNeurons,
    apc(neuron_ind).Overall_Average_Firing_Rate = overall_avgFiring(1, neuron_ind);
end

opt.FileName = sprintf('%s/%s main effects.json', main_dir, apc_type);
opt.NaN = 'null';
opt.FloatFormat = '%.2f';
cur_json = savejson('', apc, opt);