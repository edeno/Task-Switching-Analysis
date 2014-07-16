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

par_sim = [neurons.par_sim];
par_sim = reshape(par_sim, [numSim, numLevels, numNeurons]);

% Create anonymouse functions that give the population mean and standard
% deviation
mean_pop = @(stat, filter_ind) mean(mean(stat(:, :, filter_ind), 3), 1);
ci_pop = @(stat, filter_ind) quantile(mean(stat(:, :, filter_ind), 3), [.025 .975], 1);

std_pop = @(stat, filter_ind) mean(std(stat(:, :, filter_ind), [], 3), 1);
std_ci_pop = @(stat, filter_ind) quantile(std(stat(:, :, filter_ind), [], 3), [.025 .975], 1);

pct_change = @(x) (exp(x) - 1) * 100;
mult_change = @(x) exp(x);

stat = {mult_change(par_sim), mult_change(abs(par_sim)), pct_change(par_sim), pct_change(abs(par_sim))};
stat_names = {'Multiplicative Change', 'Abs. Mult. Change', 'Percent Change', 'Abs. Percent Change'};
ref_line = [1, 1, 0, 0];
xlims = {[.93 1.07], [.9 1.25], [-7 7], [-0.1 25]};

%%

level_names = gam.level_names;
cov_names = gam.cov_names;

noPrevError_ind = ~cellfun(@isempty, regexp(level_names, 'No', 'match'));

cov_rule_ind = find(ismember(cov_names, 'Rule'));
rule_names = level_names(cov_rule_ind);
cov_name_id = grp2idx(regexprep(cov_names, 'Rule:', ''));
numCovId = unique(cov_name_id);

for stat_ind = 1:length(stat),
    
    figure;
    ax = zeros(size(rule_names));
    xLim = cell(size(rule_names));
    xTick = cell(size(rule_names));
    xTickLabel = cell(size(rule_names));
    
    for rule_ind = 1:length(rule_names),
        subplot(1,2,rule_ind);
        
        levels_ind = find(~cellfun(@isempty, regexp(level_names, rule_names{rule_ind}, 'match')) & ~noPrevError_ind);
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


