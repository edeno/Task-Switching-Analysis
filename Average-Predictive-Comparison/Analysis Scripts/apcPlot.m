function apcPlot(main_dir, timePeriod, model_name, covariate_type, varargin)

% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), 'session_names', 'data_info', 'validFolders');

inParser = inputParser;
inParser.addRequired('model_name', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, validFolders)));
inParser.addRequired('covariate_type',  @ischar);
inParser.addParamValue('firing_limit', 0, @(x) isnumeric(x) & x >= 0)
inParser.addParamValue('excluded_sessions', {''}, @iscell)
inParser.addParamValue('xticklabel_names', [], @iscell)
inParser.addParamValue('xticks', {}, @(x) ismatrix(x) | iscell(x))
inParser.addParamValue('xlabel_name', {}, @ischar)
inParser.addParamValue('saveFigs', true, @islogical)
inParser.addParamValue('overwrite', true, @islogical)

inParser.parse(model_name, timePeriod, covariate_type, varargin{:});

% Add parameters to input structure after validation
apcPlot = inParser.Results;
%% Load
data_dir = sprintf('%s/%s/Models/%s/APC/%s/Collected/', data_info.processed_dir, timePeriod, model_name, covariate_type);
load(sprintf('%s/%s', data_dir, 'apc_collected.mat'));

save_dir = sprintf('%s/figs', data_dir);
if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end
cd(save_dir)
%% Setup Varaibles
% Average firing rate over all trials
baseline_firing = [avpred.baseline_firing];
session_names = {avpred.session_name};

% Exclude all neurons with a firing rate lower than firing limit or
% particular sessions
good_ind = (baseline_firing > apcPlot.firing_limit) & ~ismember(session_names, apcPlot.excluded_sessions);
session_names = session_names(good_ind);
baseline_firing = baseline_firing(good_ind);
avpred = avpred(good_ind);

% Variables to sort by
pfc = logical([avpred.pfc])';
[monkey_id, monkey_names] = grp2idx({avpred.monkey});
monkey_names = upper(monkey_names);

numPFC = sum(pfc);
numACC = sum(~pfc);

% Get APCs
numSim = avpred(1).numSim;
numNeurons = length(avpred);
numLevels = size(avpred(1).apc, 1);

apc = [avpred.apc];
apc = reshape(apc, [numLevels numSim numNeurons]);

abs_apc = [avpred.abs_apc];
abs_apc = reshape(abs_apc, [numLevels numSim numNeurons]);

rms_apc = [avpred.rms_apc];
rms_apc = reshape(rms_apc, [numLevels numSim numNeurons]);

% Create anonymouse functions that give the population mean and standard
% deviation
mean_pop = @(stat, filter_ind) mean(mean(stat(:, :, filter_ind), 3), 2);
ci_pop = @(stat, filter_ind) quantile(mean(stat(:, :, filter_ind), 3), [.025 .975], 2);

std_pop = @(stat, filter_ind) mean(std(stat(:, :, filter_ind), [], 3), 2);
std_ci_pop = @(stat, filter_ind) quantile(std(stat(:, :, filter_ind), [], 3), [.025 .975], 2);

stat = {apc, abs_apc};
stat_name = {'APC', 'ABS APC'};

%% Plot - By Brain Area

for stat_ind = 1:length(stat),
    figure;
    
    % dlPFC
    if numLevels > 1
        h1 = plot(1:numLevels, mean_pop(stat{stat_ind}, pfc), 'b-', ...
            1:numLevels, ci_pop(stat{stat_ind}, pfc), 'b--');
    else
        h1 = plot(1:numLevels, mean_pop(stat{stat_ind}, pfc), 'bo', ...
            1:numLevels, ci_pop(stat{stat_ind}, pfc), 'bo');
    end
    hold all;
    
    % ACC
    if numLevels > 1
        h2 = plot(1:numLevels, mean_pop(stat{stat_ind}, ~pfc), 'g-', ...
            1:numLevels, ci_pop(stat{stat_ind}, ~pfc), 'g--');
    else
        h2 = plot(1:numLevels, mean_pop(stat{stat_ind}, ~pfc), 'go', ...
            1:numLevels, ci_pop(stat{stat_ind}, ~pfc), 'go');
    end
    
    % Labels
    title(sprintf('%s: %s - %s', covariate_type, stat_name{stat_ind}, 'Mean'))
    legend([h1(1) h2(1)], {sprintf('%s (N = %d)', 'dlPFC', numPFC), sprintf('%s (N = %d)', 'ACC', numACC)});
    box off;
    xlim([1 numLevels] + [-.5 .5])
    if strcmp(stat_name{stat_ind}, 'ABS APC'),
        ylim([0 3]);
    else
        ylim([-3 3]);
    end
    ylabel('Spikes / s');
    if ~isempty(apcPlot.xticks),
        set(gca, 'XTick', apcPlot.xticks);
    end
    if ~isempty(apcPlot.xticklabel_names),
        set(gca, 'XTickLabel', apcPlot.xticklabel_names);
    end
    if ~isempty(apcPlot.xlabel_name),
        xlabel(apcPlot.xlabel_name);
    end
    
    % Save Fig
    save_fig_name = sprintf('%s_%s_%s_%s.fig', covariate_type, stat_name{stat_ind}, 'Mean', 'Overall');
    if apcPlot.saveFigs
        if ~exist(save_fig_name, 'file') || apcPlot.overwrite
            saveas(gcf, save_fig_name, 'fig')
        end
    end
end

%% Plot - By Monkey and Brain Area

for stat_ind = 1:length(stat),
    figure;
    for monkey_ind = 1:length(monkey_names),
        subplot(1, 3, monkey_ind)
        
        % dlPFC
        pfc_ind = pfc & (monkey_id == monkey_ind);
        if numLevels > 1
            h1 = plot(1:numLevels, mean_pop(stat{stat_ind}, pfc_ind), 'b-', ...
                1:numLevels, ci_pop(stat{stat_ind}, pfc_ind), 'b--');
        else
            h1 = plot(1:numLevels, mean_pop(stat{stat_ind}, pfc_ind), 'bo', ...
                1:numLevels, ci_pop(stat{stat_ind}, pfc_ind), 'bo');
        end
        hold all;
        
        % ACC
        acc_ind = ~pfc & (monkey_id == monkey_ind);
        if numLevels > 1
            h2 = plot(1:numLevels, mean_pop(stat{stat_ind}, acc_ind), 'g-', ...
                1:numLevels, ci_pop(stat{stat_ind}, acc_ind), 'g--');
        else
            h2 = plot(1:numLevels, mean_pop(stat{stat_ind}, acc_ind), 'go', ...
                1:numLevels, ci_pop(stat{stat_ind}, acc_ind), 'go');
        end
        
        % Labels
        legend([h1(1) h2(1)], {sprintf('%s (N = %d)', 'dlPFC', sum(pfc_ind)), sprintf('%s (N = %d)', 'ACC', sum(acc_ind))});
        title(monkey_names{monkey_ind});
        box off;
        xlim([1 numLevels] + [-.5 .5])
        if strcmp(stat_name{stat_ind}, 'ABS APC'),
            ylim([0 3]);
        else
            ylim([-3 3]);
        end
        ylabel('Spikes / s');
        if ~isempty(apcPlot.xticks),
            set(gca, 'XTick', apcPlot.xticks);
        end
        if ~isempty(apcPlot.xticklabel_names),
            set(gca, 'XTickLabel', apcPlot.xticklabel_names);
        end
        if ~isempty(apcPlot.xlabel_name),
            xlabel(apcPlot.xlabel_name);
        end
    end
    suptitle(sprintf('%s: %s - %s', covariate_type, stat_name{stat_ind}, 'Mean'))
    
    % Save Fig
    save_fig_name = sprintf('%s_%s_%s_%s.fig', covariate_type, stat_name{stat_ind}, 'Mean', 'ByMonkey');
    if apcPlot.saveFigs
        if ~exist(save_fig_name, 'file') || apcPlot.overwrite
            saveas(gcf, save_fig_name, 'fig')
        end
    end
end

%% Plot - By Brain Area - Standard Deviation

for stat_ind = 1:length(stat),
    figure;
    
    % dlPFC
    if numLevels > 1
        h1 = plot(1:numLevels, std_pop(stat{stat_ind}, pfc), 'b-', ...
            1:numLevels, std_ci_pop(stat{stat_ind}, pfc), 'b--');
    else
        h1 = plot(1:numLevels, std_pop(stat{stat_ind}, pfc), 'bo', ...
            1:numLevels, std_ci_pop(stat{stat_ind}, pfc), 'bo');
    end
    hold all;
    
    % ACC
    if numLevels > 1
        h2 = plot(1:numLevels, std_pop(stat{stat_ind}, ~pfc), 'g-', ...
            1:numLevels, std_ci_pop(stat{stat_ind}, ~pfc), 'g--');
    else
        h2 = plot(1:numLevels, std_pop(stat{stat_ind}, ~pfc), 'go', ...
            1:numLevels, std_ci_pop(stat{stat_ind}, ~pfc), 'go');
    end
    
    title(sprintf('%s: %s - %s', covariate_type, stat_name{stat_ind}, 'Std Dev.'))
    legend([h1(1) h2(1)], {sprintf('%s (N = %d)', 'dlPFC', numPFC), sprintf('%s (N = %d)', 'ACC', numACC)});
    box off;
    xlim([1 numLevels] + [-.5 .5])
    ylim([0 3]);
    ylabel('Spikes / s');
    if ~isempty(apcPlot.xticks),
        set(gca, 'XTick', apcPlot.xticks);
    end
    if ~isempty(apcPlot.xticklabel_names),
        set(gca, 'XTickLabel', apcPlot.xticklabel_names);
    end
    if ~isempty(apcPlot.xlabel_name),
        xlabel(apcPlot.xlabel_name);
    end
    
    % Save Fig
    save_fig_name = sprintf('%s_%s_%s_%s.fig', covariate_type, stat_name{stat_ind}, 'StdDev', 'Overall');
    if apcPlot.saveFigs
        if ~exist(save_fig_name, 'file') || apcPlot.overwrite
            saveas(gcf, save_fig_name, 'fig')
        end
    end
end

%% Plot - By Monkey and Brain Area - Standard Deviation

for stat_ind = 1:length(stat),
    figure;
    for monkey_ind = 1:length(monkey_names),
        subplot(1, 3, monkey_ind)
        
        % dlPFC
        pfc_ind = pfc & (monkey_id == monkey_ind);
        if numLevels > 1
            h1 = plot(1:numLevels, std_pop(stat{stat_ind}, pfc_ind), 'b-', ...
                1:numLevels, std_ci_pop(stat{stat_ind}, pfc_ind), 'b--');
        else
            h1 = plot(1:numLevels, std_pop(stat{stat_ind}, pfc_ind), 'bo', ...
                1:numLevels, std_ci_pop(stat{stat_ind}, pfc_ind), 'bo');
        end
        hold all;
        
        % ACC
        acc_ind = ~pfc & (monkey_id == monkey_ind);
        if numLevels > 1
            h2 = plot(1:numLevels, std_pop(stat{stat_ind}, acc_ind), 'g-', ...
                1:numLevels, std_ci_pop(stat{stat_ind}, acc_ind), 'g--');
        else
            h2 = plot(1:numLevels, std_pop(stat{stat_ind}, acc_ind), 'go', ...
                1:numLevels, std_ci_pop(stat{stat_ind}, acc_ind), 'go');
        end
        
        % Labels
        legend([h1(1) h2(1)], {sprintf('%s (N = %d)', 'dlPFC', sum(pfc_ind)), sprintf('%s (N = %d)', 'ACC', sum(acc_ind))});
        title(monkey_names{monkey_ind});
        box off;
        xlim([1 numLevels] + [-.5 .5])
        ylim([0 3]);
        ylabel('Spikes / s');
        if ~isempty(apcPlot.xticks),
            set(gca, 'XTick', apcPlot.xticks);
        end
        if ~isempty(apcPlot.xticklabel_names),
            set(gca, 'XTickLabel', apcPlot.xticklabel_names);
        end
        if ~isempty(apcPlot.xlabel_name),
            xlabel(apcPlot.xlabel_name);
        end
    end
    suptitle(sprintf('%s: %s - %s', covariate_type, stat_name{stat_ind}, 'Std Dev.'))
    
    % Save Fig
    save_fig_name = sprintf('%s_%s_%s_%s.fig', covariate_type, stat_name{stat_ind}, 'StdDev', 'ByMonkey');
    if apcPlot.saveFigs
        if ~exist(save_fig_name, 'file') || apcPlot.overwrite
            saveas(gcf, save_fig_name, 'fig')
        end
    end
end

end