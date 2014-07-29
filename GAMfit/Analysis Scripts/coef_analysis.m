clear all; close all; clc;
cd('C:\Users\edeno\Dropbox\GAM Analysis\Rule Response');
load('neurons.mat');

%%

pfc = logical([neurons.pfc]);
numPFC = sum(pfc);
numACC = sum(~pfc);


[monkey_id, monkey_names] = grp2idx({neurons.monkey});
monkey_id = monkey_id';

for monkey_ind = 1:length(monkey_names),
    numPFC_byMonkey(monkey_ind) = sum(pfc(monkey_id == monkey_ind));
    numACC_byMonkey(monkey_ind) = sum(~pfc(monkey_id == monkey_ind));
end

%% Baseline Firing Rate
par_est = [neurons.par_est];
baseline_firing = exp(par_est(1, :))*1000;

pfc_firing = baseline_firing(pfc);
acc_firing = baseline_firing(~pfc);

figure;
nhist([{pfc_firing}; {acc_firing}], 'median', 'noerror')

quantile(pfc_firing, [0 .25 .5 .75 1])
quantile(acc_firing, [0 .25 .5 .75 1])

for monkey_ind = 1:length(monkey_names),
    pfc_firing_byMonkey{monkey_ind} = baseline_firing(pfc & monkey_id == monkey_ind);
    acc_firing_byMonkey{monkey_ind} = baseline_firing(pfc & monkey_id == monkey_ind);
end

figure;
subplot(1,2,1);
nhist(pfc_firing_byMonkey, 'median', 'noerror');
subplot(1,2,2);
nhist(acc_firing_byMonkey, 'median', 'noerror');
%%
numSim = size(neurons(1).par_sim, 1);
numLevels = length(gam.level_names);
numNeurons = length(neurons);

% Create anonymouse functions that give the population mean and standard
% deviation
mean_pop = @(stat, filter_ind) mean(mean(stat(:, :, filter_ind), 3), 1);
ci_pop = @(stat, filter_ind) quantile(mean(stat(:, :, filter_ind), 3), [.025 .975], 1);

std_pop = @(stat, filter_ind) mean(std(stat(:, :, filter_ind), [], 3), 1);
std_ci_pop = @(stat, filter_ind) quantile(std(stat(:, :, filter_ind), [], 3), [.025 .975], 1);

mult_change = @(x) exp(x);
pct_change = @(x) (x - 1) * 100;

%% Rule Ratios

level_names = gam.level_names;
cov_names = gam.cov_names;
par_sim = [neurons.par_sim];
par_sim = reshape(par_sim, [numSim, numLevels, numNeurons]);

% Reorder covariates for interpretability
prevError_ind = ~cellfun(@isempty, regexp(level_names, 'Previous Error', 'match'));

prevError_level_names = level_names(prevError_ind);
level_names(prevError_ind) = [];
level_names = [level_names prevError_level_names];

prevError_cov_names = cov_names(prevError_ind);
cov_names(prevError_ind) = [];
cov_names = [cov_names prevError_cov_names];

prevError_par_sim = par_sim(:, prevError_ind, :);
par_sim(:, prevError_ind, :) = [];
par_sim = cat(2, par_sim, prevError_par_sim);

noPrevError_ind = ~cellfun(@isempty, regexp(level_names, 'No', 'match'));

noPrevError_level_names = level_names(noPrevError_ind);
level_names(noPrevError_ind) = [];
level_names = [level_names noPrevError_level_names];

noPrevError_cov_names = cov_names(noPrevError_ind);
cov_names(noPrevError_ind) = [];
cov_names = [cov_names noPrevError_cov_names];

noPrevError_par_sim = par_sim(:, noPrevError_ind, :);
par_sim(:, noPrevError_ind, :) = [];
par_sim = cat(2, par_sim, noPrevError_par_sim);

%
nonInteraction_cov_names = cov_names(cellfun(@isempty, regexp(cov_names, ':', 'match')));
nonInteraction_level_names = level_names(cellfun(@isempty, regexp(cov_names, ':', 'match')));
unique_cov_names = unique(nonInteraction_cov_names(~ismember(nonInteraction_cov_names, {'(Intercept)', 'Response Direction'})));

stat = {mult_change(par_sim), mult_change(abs(par_sim)), pct_change(mult_change(par_sim)), pct_change(mult_change(abs(par_sim)))};
stat_names = {'Multiplicative Change', 'Abs. Mult. Change', 'Percent Change', 'Abs. Percent Change'};
ref_line = [1, 1, 0, 0];
xlims = {[.93 1.07], [.9 1.25], [-7 7], [-0.1 25]};

for stat_ind = 1:length(stat),
    for cov_ind = 1:length(unique_cov_names),
        cur_cov_level_names = nonInteraction_level_names(ismember(nonInteraction_cov_names, unique_cov_names(cov_ind)));
        pat = sprintf('(%s:)|(:%s)', unique_cov_names{cov_ind},  unique_cov_names{cov_ind});
        cov_name_id = grp2idx(regexprep(cov_names, pat, ''));
        numCovId = unique(cov_name_id);
        figure;
        plot_ind = numSubplots(length(cur_cov_level_names));
        
        for level_ind = 1:length(cur_cov_level_names),
            subplot(plot_ind(1), plot_ind(2), level_ind);
            
            levels_ind = find(~cellfun(@isempty, regexp(level_names, cur_cov_level_names{level_ind}, 'match')));
            cur_numLevels = length(levels_ind);
            
            % dlPFC
            pfc_ind = pfc;
            
            pfc_data_mean = mean_pop(stat{stat_ind}, pfc_ind)';
            pfc_data_ci = ci_pop(stat{stat_ind}, pfc_ind)';
            
            pfc_data_ci = convert_bounds(pfc_data_mean, pfc_data_ci);
            
            h1 = herrorbar(pfc_data_mean(levels_ind), 1:cur_numLevels, pfc_data_ci(levels_ind,1), pfc_data_ci(levels_ind,2), 'bo');
            set(h1, 'MarkerSize', 6, ...
                'LineWidth', 3 ...
                );
            
            hold all;
            
            for connect_ind = 1:max(cov_name_id),
                cur_connect_ind = levels_ind(ismember(cov_name_id(levels_ind), connect_ind));
                plot(pfc_data_mean(cur_connect_ind), find(ismember(cov_name_id(levels_ind), connect_ind)), 'b')
            end
            
            % ACC
            acc_ind = ~pfc;
            
            acc_data_mean = mean_pop(stat{stat_ind}, acc_ind)';
            acc_data_ci = ci_pop(stat{stat_ind}, acc_ind)';
            
            acc_data_ci = convert_bounds(acc_data_mean, acc_data_ci);
            
            h2 = herrorbar(acc_data_mean(levels_ind), 1:cur_numLevels, acc_data_ci(levels_ind,1), acc_data_ci(levels_ind,2), 'go');
            set(h2, 'MarkerSize', 6, ...
                'LineWidth', 3 ...
                );
            
            for connect_ind = 1:max(cov_name_id),
                cur_connect_ind = levels_ind(ismember(cov_name_id(levels_ind), connect_ind));
                plot(acc_data_mean(cur_connect_ind), find(ismember(cov_name_id(levels_ind), connect_ind)), 'g')
            end
            
            
            box off;
            set(gca, 'XAxisLocation', 'top')
            set(gca, 'YTick', 1:length(levels_ind));
            set(gca, 'YTickLabel', level_names(levels_ind));
            xlabel([stat_names{stat_ind}, ' in Firing Rate']);
            xlim(xlims{stat_ind});
            ylim([0.5 cur_numLevels+0.5]);
            hline(find(diff(cov_name_id(levels_ind)))+0.5, 'k');
            vline(ref_line(stat_ind), 'r:', 'Baseline');
            
        end
    end
end

%% Rule Ratios2

level_names = gam.level_names;
cov_names = gam.cov_names;
par_sim = [neurons.par_sim];
par_sim = reshape(par_sim, [numSim, numLevels, numNeurons]);

% Reorder covariates for interpretability
prevError_ind = ~cellfun(@isempty, regexp(level_names, 'Previous Error', 'match'));

prevError_level_names = level_names(prevError_ind);
level_names(prevError_ind) = [];
level_names = [level_names prevError_level_names];

prevError_cov_names = cov_names(prevError_ind);
cov_names(prevError_ind) = [];
cov_names = [cov_names prevError_cov_names];

prevError_par_sim = par_sim(:, prevError_ind, :);
par_sim(:, prevError_ind, :) = [];
par_sim = cat(2, par_sim, prevError_par_sim);

noPrevError_ind = ~cellfun(@isempty, regexp(level_names, 'No', 'match'));

noPrevError_level_names = level_names(noPrevError_ind);
level_names(noPrevError_ind) = [];
level_names = [level_names noPrevError_level_names];

noPrevError_cov_names = cov_names(noPrevError_ind);
cov_names(noPrevError_ind) = [];
cov_names = [cov_names noPrevError_cov_names];

noPrevError_par_sim = par_sim(:, noPrevError_ind, :);
par_sim(:, noPrevError_ind, :) = [];
par_sim = cat(2, par_sim, noPrevError_par_sim);

%
nonInteraction_cov_names = cov_names(cellfun(@isempty, regexp(cov_names, ':', 'match')));
nonInteraction_level_names = level_names(cellfun(@isempty, regexp(cov_names, ':', 'match')));
unique_cov_names = unique(nonInteraction_cov_names(~ismember(nonInteraction_cov_names, {'(Intercept)'})));

stat = {mult_change(par_sim), mult_change(abs(par_sim)), pct_change(mult_change(par_sim)), pct_change(mult_change(abs(par_sim)))};
stat_names = {'Multiplicative Change', 'Abs. Mult. Change', 'Percent Change', 'Abs. Percent Change'};
ref_line = [1, 1, 0, 0];
xlims = {[.93 1.07], [.9 1.25], [-7 7], [-0.1 25]};

for stat_ind = 1:length(stat),
    figure;
    plot_ind = numSubplots(length(unique_cov_names));
    for cov_ind = 1:length(unique_cov_names),
        subplot(plot_ind(1), plot_ind(2), cov_ind);
        cur_cov_level_names = nonInteraction_level_names(ismember(nonInteraction_cov_names, unique_cov_names(cov_ind)));
        cov_name_id = grp2idx(regexprep(cov_names, [unique_cov_names{cov_ind}, ':'], ''));
        numCovId = unique(cov_name_id);
         
        
        levels_ind = find(ismember(level_names, cur_cov_level_names));
        cur_numLevels = length(levels_ind);
        
        % dlPFC
        pfc_ind = pfc;
        
        pfc_data_mean = mean_pop(stat{stat_ind}, pfc_ind)';
        pfc_data_ci = ci_pop(stat{stat_ind}, pfc_ind)';
        
        pfc_data_ci = convert_bounds(pfc_data_mean, pfc_data_ci);
        
        h1 = herrorbar(pfc_data_mean(levels_ind), 1:cur_numLevels, pfc_data_ci(levels_ind,1), pfc_data_ci(levels_ind,2), 'bo');
        set(h1, 'MarkerSize', 6, ...
            'LineWidth', 3 ...
            );
        
        hold all;
        
        for connect_ind = 1:max(cov_name_id),
            cur_connect_ind = levels_ind(ismember(cov_name_id(levels_ind), connect_ind));
            plot(pfc_data_mean(cur_connect_ind), find(ismember(cov_name_id(levels_ind), connect_ind)), 'b')
        end
        
        % ACC
        acc_ind = ~pfc;
        
        acc_data_mean = mean_pop(stat{stat_ind}, acc_ind)';
        acc_data_ci = ci_pop(stat{stat_ind}, acc_ind)';
        
        acc_data_ci = convert_bounds(acc_data_mean, acc_data_ci);
        
        h2 = herrorbar(acc_data_mean(levels_ind), 1:cur_numLevels, acc_data_ci(levels_ind,1), acc_data_ci(levels_ind,2), 'go');
        set(h2, 'MarkerSize', 6, ...
            'LineWidth', 3 ...
            );
        
        for connect_ind = 1:max(cov_name_id),
            cur_connect_ind = levels_ind(ismember(cov_name_id(levels_ind), connect_ind));
            plot(acc_data_mean(cur_connect_ind), find(ismember(cov_name_id(levels_ind), connect_ind)), 'g')
        end
        
        box off;
        set(gca, 'XAxisLocation', 'top')
        set(gca, 'YTick', 1:length(levels_ind));
        set(gca, 'YTickLabel', level_names(levels_ind));
        xlabel(unique_cov_names{cov_ind});
        xlim(xlims{stat_ind});
        ylim([0.5 cur_numLevels+0.5]);
        try
            hline(find(diff(cov_name_id(levels_ind)))+0.5, 'k');
        end
        vline(ref_line(stat_ind), 'r:', 'Baseline');
        
        
    end
    suptitle(stat_names{stat_ind});
end


%% Ratio of Rule Ratios

level_names = gam.level_names;
cov_names = gam.cov_names;
par_sim = [neurons.par_sim];
par_sim = reshape(par_sim, [numSim, numLevels, numNeurons]);

noPrevError_ind = ~cellfun(@isempty, regexp(level_names, 'No', 'match'));

noPrevError_level_names = level_names(noPrevError_ind);
level_names(noPrevError_ind) = [];
level_names = [level_names noPrevError_level_names];

noPrevError_cov_names = cov_names(noPrevError_ind);
cov_names(noPrevError_ind) = [];
cov_names = [cov_names noPrevError_cov_names];

noPrevError_par_sim = par_sim(:, noPrevError_ind, :);
par_sim(:, noPrevError_ind, :) = [];
par_sim = cat(2, par_sim, noPrevError_par_sim);

nonInteraction_cov_names = cov_names(cellfun(@isempty, regexp(cov_names, ':', 'match')));
nonInteraction_level_names = level_names(cellfun(@isempty, regexp(cov_names, ':', 'match')));
unique_cov_names = unique(nonInteraction_cov_names(~ismember(nonInteraction_cov_names, {'(Intercept)', 'Rule', 'Response Direction'})));

color_inter_name = @(x) strcat('Color:', x);
orient_inter_name = @(x) strcat('Orientation:', x);

par_sim_value = @(level_name) par_sim(:, ismember(level_names, level_name), :);
mult_ratio = @(level1, level2) mult_change(par_sim_value(level1))./mult_change(par_sim_value(level2));
abs_mult_ratio = @(level1, level2) max(mult_ratio(level1, level2), mult_ratio(level2, level1));

f(1) = figure;
f(2) = figure;

plot_ind = numSubplots(length(unique_cov_names));
xlims = {[.85 1.15], [.9 1.60]};

for cov_ind = 1:length(unique_cov_names),
    
    cur_cov_level_names = nonInteraction_level_names(ismember(nonInteraction_cov_names, unique_cov_names(cov_ind)));
    
    cur_color_inter_names = color_inter_name(cur_cov_level_names);
    cur_orient_inter_names = orient_inter_name(cur_cov_level_names);
    
    stat = {mult_ratio(cur_orient_inter_names, cur_color_inter_names), abs_mult_ratio(cur_orient_inter_names, cur_color_inter_names)};
    stat_names = {'Mult. Ratio', 'Abs. Mult. Ratio'};
    
    cur_numLevels = length(cur_cov_level_names);
    
    for stat_ind = 1:length(stat),
        
        figure(f(stat_ind));
        subplot(plot_ind(1), plot_ind(2), cov_ind);
        % dlPFC
        pfc_ind = pfc;
        
        pfc_data_mean = mean_pop(stat{stat_ind}, pfc_ind)';
        pfc_data_ci = ci_pop(stat{stat_ind}, pfc_ind)';
        
        pfc_data_ci = convert_bounds(pfc_data_mean, pfc_data_ci);
        
        h1 = herrorbar(pfc_data_mean, 1:cur_numLevels, pfc_data_ci(:,1), pfc_data_ci(:,2), 'bo');
        set(h1, 'MarkerSize', 6, ...
            'LineWidth', 3 ...
            );
        
        hold all;
        
        plot(pfc_data_mean, 1:cur_numLevels, 'b')
        
        % ACC
        acc_ind = ~pfc;
        
        acc_data_mean = mean_pop(stat{stat_ind}, acc_ind)';
        acc_data_ci = ci_pop(stat{stat_ind}, acc_ind)';
        
        acc_data_ci = convert_bounds(acc_data_mean, acc_data_ci);
        
        h2 = herrorbar(acc_data_mean, 1:cur_numLevels, acc_data_ci(:,1), acc_data_ci(:,2), 'go');
        set(h2, 'MarkerSize', 6, ...
            'LineWidth', 3 ...
            );
        
        plot(acc_data_mean, 1:cur_numLevels, 'g')
        
        box off;
        set(gca, 'XAxisLocation', 'top')
        set(gca, 'YTick', 1:cur_numLevels);
        set(gca, 'YTickLabel', cur_cov_level_names);
        xlabel([stat_names{stat_ind}, ' of Rules']);
        xlim(xlims{stat_ind});
        ylim([0.5 cur_numLevels+0.5]);
        vline(1, 'r:', 'Baseline');
        
    end
    
    
end