function [plotHandles, parameterEstAll, dev, stats] = plotBehaviorReactMultiples(model, varargin)

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
reactionTime = behavior('Reaction Time');
reactionTime = reactionTime(filter_ind);
sessionNames = behavior('Session Name');
sessionNames = sessionNames(filter_ind);
sessionNameKeys = unique(sessionNames);
numSessions = length(sessionNameKeys);

[parameterEstAll, dev, stats] = glmfit(designMatrix, reactionTime, 'normal', 'link', 'log', 'constant', 'off');

numParameters = length(parameterEstAll);
parameterEstBySession = nan(numSessions, numParameters);
for session_ind = 1:numSessions,
    sesssionID = ismember(sessionNames, sessionNameKeys(session_ind));
    parameterEstBySession(session_ind, :) = glmfit(designMatrix(sesssionID, :), reactionTime(sesssionID, :), 'normal', 'link', 'log', 'constant', 'off');
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
yTicksExpScale = 0.85:0.05:1.15;
yTicksPercentScale = (yTicksExpScale - 1) * 100;
yTicksLinearScale = log(yTicksExpScale);
transparency = 0.4;

for plot_ind = 1:length(covNames)
    subplot(subplotSize(1), subplotSize(2), plot_ind);
    if strcmp(covNames{plot_ind}, '(Intercept)'),
        plotHandles{plot_ind} = histogram(reactionTime);
        plotHandles{plot_ind}.DisplayStyle = 'stairs';
        plotHandles{plot_ind}.Normalization = 'probability';
        plotHandles{plot_ind}.EdgeColor = params.Color;
        if ~verLessThan('matlab', '8.5.1'),
            plotHandles{plot_ind}.LineWidth = 4; % Only works for matlab 2015b
        end
        plotHandles{plot_ind}.EdgeAlpha = 0.9;
        plotHandles{plot_ind}.LineWidth = 3;
        vline(exp(parameterEstAll(1)), 'Color', params.Color, 'LineType', '-', 'LineWidth', 1);
        ylabel('Probability');
        %         xlim(quantile(reactionTime, [0 1]));
        xlim([0 500]);
        title('All Reaction Times');
        box off;
        hold all;
    else
        if isInteraction(plot_ind),
            curLevels = cellfun(@(x) covInfo(x).levels, strsplit(covNames{plot_ind}, ':'), 'UniformOutput', false);
            numLevels = length(curLevels{2});
            % NOTE: Only really handles a single interaction.
            for level1_ind = 1:length(curLevels{1}),
                y_all = nan(size(curLevels{2}));
                for level2_ind = 1:length(curLevels{2}),
                    possibleLevels = [
                        curLevels{1}(level1_ind), ...
                        curLevels{2}(level2_ind), ...
                        sprintf('%s:%s', curLevels{1}{level1_ind}, curLevels{2}{level2_ind}), ...
                        sprintf('%s:%s', curLevels{2}{level2_ind}, curLevels{1}{level1_ind}) ...
                        ];
                    level_ind = ismember(gam.levelNames, possibleLevels);
                    y_all(level2_ind) = sum(parameterEstAll(level_ind));
                end
                plot(1:length(y_all), y_all, '.-', 'MarkerSize', 20, 'LineWidth', 4, 'Color', params.Color); hold on;
                t = text(length(y_all) + .1, y_all(end), sprintf('%s - Monkey %s', curLevels{1}{level1_ind}, params.Monkey));
                t.Color = params.Color;
                t.FontSize = 11;
            end
            
            set(gca, 'XTick', 1:numLevels);
            set(gca, 'XTickLabel', curLevels{2});
            
        else
            levelNames = covInfo(covNames{plot_ind}).levels;
            level_ind = ismember(gam.levelNames, levelNames);
            numLevels = sum(level_ind);
            if sum(level_ind) > 1,
                x = repmat([1:numLevels, NaN], [numSessions, 1]);
                y = [parameterEstBySession(:, level_ind), nan(numSessions, 1)];
                p = patch(x', y', params.Color);
                p.EdgeColor = params.Color;
                p.EdgeAlpha = transparency;
                hold all;
                plotHandles{plot_ind} = plot(1:sum(level_ind), parameterEstAll(level_ind), '.-', 'MarkerSize', 20, 'LineWidth', 4, 'Color', params.Color);
            else
                s  = scatter(0.9 + 0.2 * rand(numSessions,1), parameterEstBySession(:, level_ind), 40, params.Color, 'filled');
                alpha(s, transparency);
                hold all;
                plotHandles{plot_ind} = scatter(1, parameterEstAll(level_ind), 120, params.Color, 'filled');
            end
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
        
        fasterTextHandle = text(0.1, min(yTicksLinearScale) + .01, {'Faster RT', '\downarrow'});
        fasterTextHandle.FontSize = 11;
        fasterTextHandle.Color = [153, 153, 153] / 255;
        fasterTextHandle.VerticalAlignment = 'bottom';
        slowerTextHandle = text(0.1, max(yTicksLinearScale) - .01, {'\uparrow', 'Slower RT'});
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
