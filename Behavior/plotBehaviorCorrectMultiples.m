function [plotHandles, parameterEstAll, dev, stats] = plotBehaviorCorrectMultiples(model, varargin)

main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), 'covInfo');
load(sprintf('%s/Behavior/behavior.mat', main_dir));
behavior = mergeMap(behavior);

inParser = inputParser;
inParser.addRequired('model', @ischar);
inParser.addParameter('Monkey', 'All');
inParser.addParameter('Session', 'All');
inParser.addParameter('correctTrialsOnly', false);
inParser.addParameter('Color', 'blue');
inParser.parse(model, varargin{:});
params = inParser.Results;

monkey = bsxfun(@or, strcmpi({params.Monkey}, behavior('Monkey')), strcmpi(params.Monkey, 'All'));
sessions = bsxfun(@or, strcmpi({params.Session}, behavior('Session Name')), strcmpi(params.Session, 'All'));
filter_ind = monkey & sessions;
if params.correctTrialsOnly,
    filter_ind = filter_ind & behavior('Correct');
end

[designMatrix, gam] = gamModelMatrix(model, behavior, covInfo, 'level_reference', 'Reference');
designMatrix = designMatrix(filter_ind, :);

% Reaction Time
correct = double(behavior('Correct'));
correct = correct(filter_ind);
sessionNames = behavior('Session Name');
sessionNames = sessionNames(filter_ind);
sessionNameKeys = unique(sessionNames);
numSessions = length(sessionNameKeys);

[parameterEstAll, dev, stats] = glmfit(designMatrix, correct, 'binomial','link','logit', 'constant', 'off');

numParameters = length(parameterEstAll);
parameterEstBySession = nan(numSessions, numParameters);
for session_ind = 1:numSessions,
    sesssionID = ismember(sessionNames, sessionNameKeys(session_ind));
    parameterEstBySession(session_ind, :) = glmfit(designMatrix(sesssionID, :), correct(sesssionID, :), 'binomial','link','logit', 'constant', 'off');
end

covNames = gam.covNames;
covNames = unique(covNames, 'stable');
removeInteraction = false(length(covNames), 1);
for cov_ind = 1:length(covNames)
    removeInteraction(cov_ind) = any(cellfun(@(x) ~isempty(x), regexp(covNames, sprintf('(%s:.)|(.:%s)', covNames{cov_ind}, covNames{cov_ind}))));
end
covNames(removeInteraction) = [];

levelByCov = cell(size(covNames));
for cov_ind = 1:length(covNames),
    levelByCov{cov_ind} = gam.levelNames(ismember(gam.covNames, covNames{cov_ind}));
end
isInteraction = cellfun(@(x) ~isempty(x), regexp(covNames, ':'));

subplotSize = numSubplots(length(covNames));
plotHandles = cell(size(covNames));
yTicksExpScale = 0.25:0.25:4;
yTicksPercentScale = (yTicksExpScale - 1) * 100;
yTicksLinearScale = log(yTicksExpScale);
transparency = 0.4;

for plot_ind = 1:length(covNames)
    subplot(subplotSize(1), subplotSize(2), plot_ind);
    if strcmp(covNames{plot_ind}, '(Intercept)'),
        plotHandles{plot_ind} = histogram(accumarray(grp2idx(sessionNames), correct, [], @nanmean));
        plotHandles{plot_ind}.DisplayStyle = 'stairs';
        plotHandles{plot_ind}.Normalization = 'probability';
        plotHandles{plot_ind}.EdgeColor = params.Color;
        if ~verLessThan('matlab', '8.5.1'),
            plotHandles{plot_ind}.LineWidth = 4; % Only works for matlab 2015b
        end
        plotHandles{plot_ind}.EdgeAlpha = 0.9;
        plotHandles{plot_ind}.LineWidth = 3;
        vline(nanmean(correct), 'Color', params.Color, 'LineType', '-', 'LineWidth', 1);
        ylabel('Probability');
        xlim([0 1]);
        title('Percent Correct By Session');
        box off;
        hold all;
    else
        if isInteraction(plot_ind),
            curLevels = cellfun(@(x) covInfo(x).levels, strsplit(covNames{plot_ind}, ':'), 'UniformOutput', false);
            baselineLevel = cellfun(@(x) covInfo(x).baselineLevel, strsplit(covNames{plot_ind}, ':'), 'UniformOutput', false);
            curLevels{2} = curLevels{2}(~ismember(curLevels{2}, baselineLevel));
            numLevels = length(curLevels{2});
            % NOTE: Only really handles a single interaction.
            for level1_ind = 1:length(curLevels{1}),
                y_all = nan(size(curLevels{2}));
                 y_se = nan(length(curLevels{2}), 2);
                for level2_ind = 1:length(curLevels{2}),
                    possibleLevels = [
                        curLevels{1}(level1_ind), ...
                        curLevels{2}(level2_ind), ...
                        sprintf('%s:%s', curLevels{1}{level1_ind}, curLevels{2}{level2_ind}), ...
                        sprintf('%s:%s', curLevels{2}{level2_ind}, curLevels{1}{level1_ind}) ...
                        ];
                    level_ind = ismember(gam.levelNames, possibleLevels);
                    y_all(level2_ind) = sum(parameterEstAll(level_ind));
                    y_se(level2_ind, 1) = sum(parameterEstAll(level_ind) + stats.se(level_ind));
                    y_se(level2_ind, 2) = sum(parameterEstAll(level_ind) - stats.se(level_ind));
                end
                
                l = line([1:length(y_all); 1:length(y_all)], y_se');
                [l.Color] = deal(params.Color); hold all;
                plotHandles{plot_ind} = plot(1:length(y_all), y_all, '.-', 'MarkerSize', 20, 'LineWidth', 4, 'Color', params.Color); hold on;
                t = text(length(y_all) + .1, y_all(end), sprintf('%s - Monkey %s', curLevels{1}{level1_ind}, params.Monkey));
                t.FontSize = 11;
                t.Color = params.Color;
            end
            
            set(gca, 'XTick', 1:numLevels);
            set(gca, 'XTickLabel', curLevels{2});
            
        else
            levelNames = covInfo(covNames{plot_ind}).levels;
            level_ind = ismember(gam.levelNames, levelNames);
            numLevels = sum(level_ind);
            if sum(level_ind) > 1,
                plotHandles{plot_ind} = plot(1:sum(level_ind), parameterEstAll(level_ind), '.-', 'MarkerSize', 20, 'LineWidth', 4, 'Color', params.Color);
                hold all;
            else
                s  = scatter(0.9 + 0.2 * rand(numSessions,1), parameterEstBySession(:, level_ind), 40, params.Color, 'filled');
                alpha(s, transparency);
                hold all;
                plotHandles{plot_ind} = scatter(1, parameterEstAll(level_ind), 120, params.Color, 'filled');
            end
            l = line([1:numLevels; 1:numLevels], [parameterEstAll(level_ind) - stats.se(level_ind), parameterEstAll(level_ind) + stats.se(level_ind)]');
            [l.Color] = deal(params.Color);
            t = text(numLevels + 0.2, parameterEstAll(find(level_ind, 1, 'last')), sprintf('Monkey %s', params.Monkey));
            t.Color = params.Color;
            t.FontSize = 11;
            set(gca, 'XTick', 1:numLevels);
            set(gca, 'XTickLabel', gam.levelNames(level_ind));
        end
        ylim(quantile(yTicksLinearScale, [0 1]))
        xlim([0, numLevels+1]);
        set(gca, 'YTick', yTicksLinearScale)
        set(gca, 'YTickLabel', yTicksPercentScale)
        
        fasterTextHandle = text(0.1, min(yTicksLinearScale) + .01, {'Decrease in Odds of Correct Response', '\downarrow'});
        fasterTextHandle.FontSize = 11;
        fasterTextHandle.Color = [153, 153, 153] / 255;
        fasterTextHandle.VerticalAlignment = 'bottom';
        slowerTextHandle = text(0.1, max(yTicksLinearScale) - .01, {'\uparrow', 'Increase in Odds of Correct Response'});
        slowerTextHandle.FontSize = 11;
        slowerTextHandle.Color = [153, 153, 153] / 255;
        slowerTextHandle.VerticalAlignment = 'top';
        title(covNames{plot_ind});
        hline(0, 'k');
        ylabel('Change from Baseline (%)');
        hold all;
        box off;
    end
end
end
