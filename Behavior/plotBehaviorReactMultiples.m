function [plotHandles, parameterEstAll, dev, stats] = plotBehaviorReactMultiples(model, varargin)

main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), 'covInfo');
load(sprintf('%s/Behavior/behavior.mat', main_dir));
behavior = mergeMap(behavior);

inParser = inputParser;
inParser.addRequired('model', @ischar);
inParser.addParameter('Monkey', 'All');
inParser.addParameter('Session', 'All');
inParser.addParameter('Color', 'blue');
inParser.parse(model, varargin{:});
params = inParser.Results;

monkey = bsxfun(@or, ismember(behavior('Monkey'), {params.Monkey}), strcmp(params.Monkey, 'All'));
sessions = bsxfun(@or, ismember(behavior('Session Name'), {params.Session}), strcmp(params.Session, 'All'));
filter_ind = monkey & sessions;

[designMatrix, gam] = gamModelMatrix(model, behavior, covInfo, 'level_reference', 'Reference');
% Reaction Time
reactionTime = behavior('Reaction Time');
sessionNames = behavior('Session Name');
sessionNames = sessionNames(filter_ind);
sessionNameKeys = unique(sessionNames);
numSessions = length(sessionNameKeys);

[parameterEstAll, dev, stats] = glmfit(designMatrix(filter_ind, :), reactionTime(filter_ind), 'normal', 'link', 'log', 'constant', 'off');

numParameters = length(parameterEstAll);
parameterEstBySession = nan(numSessions, numParameters);
for session_ind = 1:numSessions,
    sesssionID = ismember(sessionNames, sessionNameKeys(session_ind));
    parameterEstBySession(session_ind, :) = glmfit(designMatrix(sesssionID, :), reactionTime(sesssionID, :), 'normal', 'link', 'log', 'constant', 'off');
end

covNames = unique(gam.covNames, 'stable');
subplotSize = numSubplots(length(covNames));
plotHandles = cell(size(covNames));
yTicksExpScale = 0.85:0.05:1.15;
yTicksPercentScale = (yTicksExpScale - 1) * 100;
yTicksLinearScale = log(yTicksExpScale);
transparency = 0.2;

for plot_ind = 1:length(covNames)
    subplot(subplotSize(1), subplotSize(2), plot_ind);
    if strcmp(covNames{plot_ind}, '(Intercept)'),
        plotHandles{plot_ind} = histogram(reactionTime(filter_ind, :));
        plotHandles{plot_ind}.DisplayStyle = 'stairs';
        plotHandles{plot_ind}.Normalization = 'probability';
        plotHandles{plot_ind}.EdgeColor = params.Color;
        plotHandles{plot_ind}.LineWidth = 4;
        vline(exp(parameterEstAll(1)), 'Color', params.Color, 'LineType', '-', 'LineWidth', 1);
        ylabel('Probability');
        xlim(quantile(reactionTime, [0 1]));
        title('All Reaction Times');
        box off;
        hold all;
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
        ylim(quantile(yTicksLinearScale, [0 1]))
        xlim([0.5, numLevels+.5]);
        set(gca, 'YTick', yTicksLinearScale)
        set(gca, 'YTickLabel', yTicksPercentScale)
        set(gca, 'XTick', 1:numLevels);
        set(gca, 'XTickLabel', gam.levelNames(level_ind));
        title(covNames{plot_ind});
        hline(0, 'k');
        ylabel('Percent Change');
        hold all;
        box off;
    end
end

end