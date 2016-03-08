function apcPloting_simple(apc)

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
markSize = 5;
offset = [0 0];

if strcmp(apc_type, 'abs_apc'),
    if isNormalized,
        xlimits = [0.0 1.2];
        xTick = 0.3:0.3:0.9;
    else
        xlimits = [0 6];
        xTick = 2:2:4;
    end
else
    if isNormalized,
        xlimits = [-1.2 1.2];
        xTick = -0.9:0.3:0.9;
    else
        xlimits = [-6 6];
        xTick = -4:2:4;
    end
end

set(0,'DefaultAxesTickDir', 'in')

figure;
subplot_axes = tight_subplot(4, 6, [.02 .01],[0.02 0.07],[0.08 0.01]);
for brain_ind = 1:2,
    for curTimePeriod_ind = 1:length(timePeriods);
        
        %% Rule By Previous Error
        prev_error_ind = ismember(valid_covariates, 'Previous Error History');
        subplot_ind = (12 * (brain_ind - 1)) + curTimePeriod_ind;
        axes(subplot_axes(subplot_ind))
        
        % Error
        
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
        
        
        % No Error
        
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
        set(gca,'YTick',1:10);
        if ismember(subplot_ind, [1 13]),
            
            ylabel_names = strseq('Prev. Error', 1:10);
            set(gca,'YTickLabel', ylabel_names(10:-1:1));
        else
            set(gca,'YTickLabel',[]);
            %             set(gca,'YTick',[]);
            %             set(gca,'YColor',[1 1 1])
        end
        box off;
        xlim(xlimits);
        ylim([.8 10.2]);
        set(gca, 'XTick', xTick);
        if subplot_ind <= 6,
            title(timePeriods{curTimePeriod_ind});
            set(gca, 'XAxisLocation', 'top');
            xlim(xlimits);
        else
            set(gca,'XTickLabel',[]);
        end
        line_handle = line(xTick(ones(2,1), :), [ones(1,size(xTick, 2)); 11.1*ones(1,size(xTick, 2))]);
        set(line_handle, 'LineWidth', 0.1, 'Color', 'k')
        box on;
        
        %% Rule by Switch History
        switch_hist_ind = ismember(valid_covariates, 'Switch History');
        subplot_ind = 6 + (12 * (brain_ind - 1)) + curTimePeriod_ind;
        axes(subplot_axes(subplot_ind))
        
        % Incongruent
        
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
        
        if ismember(subplot_ind, [7 19]),
            set(gca,'YTick',1:11);
            ylabel_names = [strseq('Repetition', 1:10); 'Repetition11+'];
            set(gca,'YTickLabel',ylabel_names(11:-1:1));
        else
            set(gca,'YTickLabel',[]);
           
        end
        set(gca,'XTickLabel',[]);
         set(gca, 'XTick', xTick);
        
        box off;
        xlim(xlimits);
        ylim([1 11.1]);
        line_handle = line(xTick(ones(2,1), :), [ones(1,size(xTick, 2)); 11.1*ones(1,size(xTick, 2))]);
        set(line_handle, 'LineWidth', 0.1, 'Color', 'k')
        box on;
        
        
    end
end

% % - Build title axes and title.
% suptitle(timePeriods{curTimePeriod_ind});
%
% % Save Figure
% if isNormalized,
%     norm_name = '_norm';
% else
%     norm_name = '';
% end
% if iscell(monkey),
%     monkey = 'All';
% end
%
% save_file_name = sprintf('%s/Figures/%s/%s_%s%s.fig', main_dir, timePeriods{curTimePeriod_ind}, apc_type, monkey, norm_name);
%
% saveas(gcf, save_file_name, 'fig');
