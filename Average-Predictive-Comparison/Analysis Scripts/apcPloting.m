function apcPloting(apc)
% clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
mean_covAPC = apc.mean_covAPC;
ci_covAPC = apc.ci_covAPC;
mean_ruleByAPC = apc.mean_ruleByAPC;
ci_ruleByAPC = apc.ci_ruleByAPC;
valid_covariates = apc.valid_covariates;
timePeriods = apc.timePeriods;
brain_areas = apc.brain_area_names;
apc_type = apc.apc_type;
isNormalized = apc.isNormalized;
monkey = apc.monkey;

%% -----------------Plotting-----------------------------------------------


% setup colors for each brain area
colororder = [
    0.00  0.50  0.00
    0.00  0.00  1.00
    ];
markSize = 7;
offset = [0 0];

if strcmp(apc_type, 'abs_apc'),
    if isNormalized,
        xlimits = [0 1.3];
        xTick = 0:0.2:1;
    else
        xlimits = [0 10];
        xTick = 0:2:10;
    end
else
    if isNormalized,
        xlimits = [-2 2];
        xTick = -2:0.5:2;
    else
        xlimits = [-2 2];
        xTick = -2:0.5:2;
    end
end

for curTimePeriod_ind = 1:length(timePeriods);
    figure;
    
    %% Rule
    rule_ind = ismember(valid_covariates, 'Rule');
    subplot(9, 3, 1:2)
    for brain_ind = 1:2,
        
        rule_mean = mean_covAPC{curTimePeriod_ind, rule_ind, brain_ind};
        rule_ci = [ci_covAPC{curTimePeriod_ind, rule_ind, :, brain_ind}];
        
        h(brain_ind) = plot(rule_mean, offset(brain_ind) + 1, '.', 'Color', colororder(brain_ind, :), 'MarkerSize', 30);
        hold all;
        plot(rule_ci, offset(brain_ind) + [1 1], '-', 'Color', colororder(brain_ind, :), 'LineWidth', 3);
        
    end
    
    set(gca,'YTickLabel','Overall');
    set(gca,'YTick',1);
    set(gca, 'XAxisLocation', 'top');
    box off;
    xlim(xlimits);
    set(gca, 'XTick', xTick);
    xlabel({'Change in Firing Rate due to Rule', 'abs(Orient. Rule - Color Rule)'})
    %%
    subplot(9, 3, 3)
    set(gca,'YTickLabel',[]);
    set(gca,'YTick',[]);
    set(gca, 'XAxisLocation', 'top');
    
    box off;
    xlim(xlimits);
    set(gca, 'XTick', xTick);
    set(gca,'YColor',[1 1 1])
    xlabel({'Change in Firing Rate due to Cognitive Demand', 'abs(High Demand - Low Demand)'})
    %% Rule By Previous Error
    prev_error_ind = ismember(valid_covariates, 'Previous Error History');
    subplot(9, 3, [4 5 7 8 10 11]);
    
    % Error
    for brain_ind = 1:2,
        error_ind = 2:2:20;
        
        mean_prev_error = mean_ruleByAPC{curTimePeriod_ind, prev_error_ind, brain_ind};
        mean_prev_error = mean_prev_error(error_ind);
        
        ci_prev_error = [ci_ruleByAPC{curTimePeriod_ind, prev_error_ind, :, brain_ind}];
        ci_prev_error = ci_prev_error(error_ind, :)';
        
        plot(mean_prev_error(10:-1:1), offset(brain_ind) +  [1:10], ...
            '-o', ...
            'LineWidth', 3, ...
            'MarkerFaceColor', colororder(brain_ind, :), ...
            'MarkerSize', markSize, ...
            'Color', colororder(brain_ind, :));
        hold all;
        line(ci_prev_error(:, 10:-1:1), offset(brain_ind) + [1:10; 1:10], ...
            'LineWidth', 1.5, ...
            'Color', colororder(brain_ind, :));
        
    end
    
    % No Error
    for brain_ind = 1:2,
        error_ind = 1:2:20;
        
        mean_prev_error = mean_ruleByAPC{curTimePeriod_ind, prev_error_ind, brain_ind};
        mean_prev_error = mean_prev_error(error_ind);
        
        ci_prev_error = [ci_ruleByAPC{curTimePeriod_ind, prev_error_ind, :, brain_ind}];
        ci_prev_error = ci_prev_error(error_ind, :)';
        
        plot(mean_prev_error(10:-1:1), offset(brain_ind) +  [1:10], ...
            '-s', ...
            'LineWidth', 3, ...
            'MarkerFaceColor', colororder(brain_ind, :), ...
            'MarkerSize', markSize, ...
            'Color', colororder(brain_ind, :));
        hold all;
        line(ci_prev_error(:, 10:-1:1),  offset(brain_ind) + [1:10; 1:10], ...
            'LineWidth', 2, ...
            'Color', colororder(brain_ind, :));
        
    end
    
    set(gca,'XTickLabel',[]);
    set(gca,'XTick',[]);
    set(gca,'XColor',[1 1 1])
    set(gca,'YTick',1:10);
    ylabel_names = strseq('Prev. Error', 1:10);
    set(gca,'YTickLabel', ylabel_names(10:-1:1));
    box off;
    xlim(xlimits);
    ylim([.8 10.2]);
    %% Previous Error
    prev_error_ind = ismember(valid_covariates, 'Previous Error History');
    subplot(9, 3, [6 9 12]);
    
    % Error
    for brain_ind = 1:2,
        
        mean_prev_error = mean_covAPC{curTimePeriod_ind, prev_error_ind, brain_ind};
        
        ci_prev_error = [ci_covAPC{curTimePeriod_ind, prev_error_ind, :, brain_ind}]';
        
        plot(mean_prev_error(10:-1:1), 1:10, ...
            '-o', ...
            'LineWidth', 3, ...
            'MarkerFaceColor', colororder(brain_ind, :), ...
            'MarkerSize', markSize, ...
            'Color', colororder(brain_ind, :));
        hold all;
        line(ci_prev_error(:,10:-1:1), [1:10; 1:10], ...
            'LineWidth', 2, ...
            'Color', colororder(brain_ind, :));
        
    end
    
    set(gca,'XTickLabel',[]);
    set(gca,'XTick',[]);
    set(gca,'XColor',[1 1 1])
    set(gca,'YTick',1:10);
    ylabel_names = strseq('Prev. Error', 1:10);
    set(gca,'YTickLabel',ylabel_names(10:-1:1));
    set(gca, 'YAxisLocation', 'right');
    box off;
    xlim(xlimits);
    ylim([1 10]);
    
    %% Rule by Congruency History
    con_hist_ind = ismember(valid_covariates, 'Congruency History');
    subplot(9, 3, [13 14]);
    
    % Incongruent
    for brain_ind = 1:2,
        incon_ind = 2:2:4;
        
        mean_incon = mean_ruleByAPC{curTimePeriod_ind, con_hist_ind, brain_ind};
        mean_incon = mean_incon(incon_ind);
        
        ci_incon = [ci_ruleByAPC{curTimePeriod_ind, con_hist_ind, :, brain_ind}];
        ci_incon = ci_incon(incon_ind, :)';
        
        plot(mean_incon(2:-1:1), 1:2, ...
            '-o', ...
            'LineWidth', 3, ...
            'MarkerFaceColor', colororder(brain_ind, :), ...
            'MarkerSize', markSize, ...
            'Color', colororder(brain_ind, :));
        hold all;
        line(ci_incon(:,2:-1:1), [1:2; 1:2], ...
            'LineWidth', 1.5, ...
            'Color', colororder(brain_ind, :));
        
    end
    
    % Congruent
    for brain_ind = 1:2,
        incon_ind = 1:2:4;
        
        mean_incon = mean_ruleByAPC{curTimePeriod_ind, con_hist_ind, brain_ind};
        mean_incon = mean_incon(incon_ind);
        
        ci_incon = [ci_ruleByAPC{curTimePeriod_ind, con_hist_ind, :, brain_ind}];
        ci_incon = ci_incon(incon_ind, :)';
        
        plot(mean_incon(2:-1:1), 1:2, ...
            '-s', ...
            'LineWidth', 3, ...
            'MarkerFaceColor', colororder(brain_ind, :), ...
            'MarkerSize', markSize, ...
            'Color', colororder(brain_ind, :));
        hold all;
        line(ci_incon(:, 2:-1:1), [1:2; 1:2], ...
            'LineWidth', 1.5, ...
            'Color', colororder(brain_ind, :));
        
    end
    
    set(gca,'XTickLabel',[]);
    set(gca,'XTick',[]);
    set(gca,'XColor',[1 1 1])
    set(gca,'YTick',1:2);
    ylabel_names = {'Current Congruency', 'Prev. Congruency'};
    set(gca,'YTickLabel',ylabel_names);
    box off;
    xlim(xlimits);
    ylim([1 2]);
    
    %% Congruency History
    con_hist_ind = ismember(valid_covariates, 'Congruency History');
    subplot(9, 3, [15]);
    
    % Difference in congruency
    
    for brain_ind = 1:2,
        
        mean_incon = mean_covAPC{curTimePeriod_ind, con_hist_ind, brain_ind};
        
        ci_incon = [ci_covAPC{curTimePeriod_ind, con_hist_ind, :, brain_ind}]';
        
        plot(mean_incon(2:-1:1), 1:2, ...
            '-o', ...
            'LineWidth', 3, ...
            'MarkerFaceColor', colororder(brain_ind, :), ...
            'MarkerSize', markSize, ...
            'Color', colororder(brain_ind, :));
        hold all;
        line(ci_incon(:,2:-1:1), [1:2; 1:2], ...
            'LineWidth', 2, ...
            'Color', colororder(brain_ind, :));
        
    end
    
    set(gca,'XTickLabel',[]);
    set(gca,'XTick',[]);
    set(gca,'XColor',[1 1 1])
    set(gca,'YTick',1:2);
    ylabel_names = {'Current Congruency', 'Prev. Congruency'};
    set(gca,'YTickLabel',ylabel_names);
    set(gca, 'YAxisLocation', 'right');
    box off;
    xlim(xlimits);
    ylim([1 2]);
    
    %% Rule by Switch History
    switch_hist_ind = ismember(valid_covariates, 'Switch History');
    subplot(9, 3, [16 17 19 20 22 23]);
    
    % Incongruent
    for brain_ind = 1:2,
        
        mean_switch = mean_ruleByAPC{curTimePeriod_ind, switch_hist_ind, brain_ind};
        
        ci_switch = [ci_ruleByAPC{curTimePeriod_ind, switch_hist_ind, :, brain_ind}]';
        
        plot(mean_switch(11:-1:1), 1:11, ...
            '-o', ...
            'LineWidth', 3, ...
            'MarkerFaceColor', colororder(brain_ind, :), ...
            'MarkerSize', markSize, ...
            'Color', colororder(brain_ind, :));
        hold all;
        plot(mean_switch(11), 1, ...
            '-s', ...
            'LineWidth', 3, ...
            'MarkerFaceColor', colororder(brain_ind, :), ...
            'MarkerSize', markSize, ...
            'Color', colororder(brain_ind, :));
        line(ci_switch(:,11:-1:1), [1:11; 1:11], ...
            'LineWidth', 1.5, ...
            'Color', colororder(brain_ind, :));
        
    end
    
    set(gca,'XTickLabel',[]);
    set(gca,'XTick',[]);
    set(gca,'XColor',[1 1 1])
    set(gca,'YTick',1:11);
    ylabel_names = [strseq('Repetition', 1:10); 'Repetition11+'];
    set(gca,'YTickLabel',ylabel_names(11:-1:1));
    box off;
    xlim(xlimits);
    ylim([1 11]);
    
    %% Switch History
    
    switch_hist_ind = ismember(valid_covariates, 'Switch History');
    subplot(9, 3, [18 21 24]);
    
    for brain_ind = 1:2,
        
        mean_switch = mean_covAPC{curTimePeriod_ind, switch_hist_ind, brain_ind};
        
        ci_switch = [ci_covAPC{curTimePeriod_ind, switch_hist_ind, :, brain_ind}]';
        
        plot(mean_switch(10:-1:1), 1:10, ...
            '-o', ...
            'LineWidth', 3, ...
            'MarkerFaceColor', colororder(brain_ind, :), ...
            'MarkerSize', markSize, ...
            'Color', colororder(brain_ind, :));
        hold all;
        line(ci_switch(:,10:-1:1), [1:10; 1:10], ...
            'LineWidth', 1.5, ...
            'Color', colororder(brain_ind, :));
        
    end
    
    set(gca,'XTickLabel',[]);
    set(gca,'XTick',[]);
    set(gca,'XColor',[1 1 1])
    set(gca,'YTick',1:10);
    ylabel_names = strseq('Repetition', 1:10);
    set(gca,'YTickLabel',ylabel_names(10:-1:1));
    set(gca, 'YAxisLocation', 'right');
    box off;
    xlim(xlimits);
    ylim([1 10]);
    
    %% Rule by Prep
    prep_ind = ismember(valid_covariates, 'Normalized Prep Time');
    subplot(9, 3, [25 26]);
    
    % Low
    for brain_ind = 1:2,
        
        mean_prep = mean_ruleByAPC{curTimePeriod_ind, prep_ind, brain_ind};
        mean_prep = mean_prep(1);
        
        ci_prep = [ci_ruleByAPC{curTimePeriod_ind, prep_ind, :, brain_ind}]';
        
        plot(mean_prep, 1, ...
            '-s', ...
            'LineWidth', 3, ...
            'MarkerFaceColor', colororder(brain_ind, :), ...
            'MarkerSize', markSize, ...
            'Color', colororder(brain_ind, :));
        hold all;
        line(ci_prep, [1; 1], ...
            'LineWidth', 1.5, ...
            'Color', colororder(brain_ind, :));
        
    end
    
    % High
    for brain_ind = 1:2,
        
        mean_prep = mean_ruleByAPC{curTimePeriod_ind, prep_ind, brain_ind};
        mean_prep = mean_prep(2);
        
        ci_prep = [ci_ruleByAPC{curTimePeriod_ind, prep_ind, :, brain_ind}]';
        
        plot(mean_prep, 1, ...
            '-o', ...
            'LineWidth', 3, ...
            'MarkerFaceColor', colororder(brain_ind, :), ...
            'MarkerSize', markSize, ...
            'Color', colororder(brain_ind, :));
        hold all;
        line(ci_prep, [1; 1], ...
            'LineWidth', 1.5, ...
            'Color', colororder(brain_ind, :));
        
    end
    
    set(gca,'XTickLabel',[]);
    set(gca,'XTick',[]);
    set(gca,'XColor',[1 1 1])
    set(gca,'YTick',1);
    set(gca,'YTickLabel', 'Prep. Time');
    box off;
    xlim(xlimits);
    ylim([0.9 1.1]);
    
    %% Prep Time
    
    prep_ind = ismember(valid_covariates, 'Normalized Prep Time');
    subplot(9, 3, [27]);
    
    
    for brain_ind = 1:2,
        
        mean_prep = mean_covAPC{curTimePeriod_ind, prep_ind, brain_ind};
        
        ci_prep = [ci_covAPC{curTimePeriod_ind, prep_ind, :, brain_ind}]';
        
        plot(mean_prep, 1, ...
            '-o', ...
            'LineWidth', 3, ...
            'MarkerFaceColor', colororder(brain_ind, :), ...
            'MarkerSize', markSize, ...
            'Color', colororder(brain_ind, :));
        hold all;
        line(ci_prep, [1; 1], ...
            'LineWidth', 1.5, ...
            'Color', colororder(brain_ind, :));
        
    end
    
    set(gca,'XTickLabel',[]);
    set(gca,'XTick',[]);
    set(gca,'XColor',[1 1 1])
    set(gca,'YTick',1);
    set(gca,'YTickLabel', 'Prep. Time');
    set(gca, 'YAxisLocation', 'right');
    box off;
    xlim(xlimits);
    ylim([.9 1.1]);
    % - Build title axes and title.
    suptitle(timePeriods{curTimePeriod_ind});
    
    % Save Figure
    if isNormalized,
        norm_name = '_norm';
    else
        norm_name = '';
    end
    if iscell(monkey),
        monkey = 'All';
    end
    
    save_file_name = sprintf('%s/Figures/%s/%s_%s%s.fig', main_dir, timePeriods{curTimePeriod_ind}, apc_type, monkey, norm_name);
    
    saveas(gcf, save_file_name, 'fig');
end
