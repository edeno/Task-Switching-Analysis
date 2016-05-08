function plotPopPerm(covariate, timePeriod)
workingDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', workingDir), 'covInfo', 'colorInfo');
load(sprintf('%s/Permutation-Analysis/Analysis/colllectedPermAnalysis.mat', workingDir))

obs = [values.obs];
obsNames = values(1).obsNames;
obsTimePeriod = values(1).obsTimePeriod;
brainArea = {values.brainArea};

getBrainArea = @(x) ismember(brainArea, x);
getTimePeriod = @(x) ismember(obsTimePeriod, x);
getObs = @(x) ismember(obsNames, x);

info = covInfo(covariate);
obs_ind = find(getObs(info.levels) & getTimePeriod(timePeriod));
baseline_ind = ismember(info.levels, info.baselineLevel);

diffName = cellfun(@(x) strsplit(x, ' - '), comparisonNames, 'UniformOutput', false);
diffName = cat(1, diffName{:});
getObsDiff = @(x, t) ismember(diffName(:, 1), x) & ismember(values(1).timePeriod, t);

sigMask = double(h(getObsDiff(info.levels, timePeriod), :));
sigMask(~sigMask) = NaN;
levelNames = info.levels(~baseline_ind);
numLevels = length(levelNames);

if ~info.isHistory,
    baselineObs = repmat(obs(obs_ind(baseline_ind), :), [sum(~baseline_ind), 1]);
    levelObs = obs(obs_ind(~baseline_ind), :);
    baselineLevelNames = repmat(info.levels(baseline_ind), [numLevels, 1]);
else
    baselineObs = reshape(obs(obs_ind, :), 2, sum(baseline_ind), numTotalNeurons);
    levelObs = squeeze(baselineObs(1, :, :));
    baselineObs = squeeze(baselineObs(2, :, :));
    baselineLevelNames = info.levels(baseline_ind);
end

maxACCRate = max(reshape(obs(getTimePeriod(timePeriod), getBrainArea('ACC')), [], 1));
maxACCRate = ceil(maxACCRate / 10) * 10;
maxDLPFCRate = max(reshape(obs(getTimePeriod(timePeriod), getBrainArea('dlPFC')), [], 1));
maxDLPFCRate = ceil(maxDLPFCRate / 10) * 10;

f = figure;
f.Name = sprintf('%s - %s', timePeriod, covariate);

for level_ind = 1:numLevels,
    subplot(2, numLevels, level_ind);
    plot(baselineObs(level_ind, getBrainArea('ACC')), levelObs(level_ind, getBrainArea('ACC')), ...
        '.', 'MarkerSize', 12, 'Color', [153, 153, 153] ./ 255);
    hold all;
    plot(baselineObs(level_ind, getBrainArea('ACC')), levelObs(level_ind, getBrainArea('ACC')) .* sigMask(level_ind, getBrainArea('ACC')), ...
        '.', 'MarkerSize', 12, 'Color', colorInfo(levelNames{level_ind}));
    title(sprintf('ACC - %s' , levelNames{level_ind}));
    text(5, maxACCRate - 5, sprintf('%d / %d', nansum(sigMask(level_ind, getBrainArea('ACC'))), sum(getBrainArea('ACC'))));
    box off;
    axis square;
    set(gca, 'TickLength', [0 0]);
    set(gca, 'XTick', [0, (maxACCRate / 2), maxACCRate]);
    set(gca, 'YTick', [0, (maxACCRate / 2), maxACCRate]);
    ylim([0 maxACCRate]);
    xlim([0 maxACCRate]);
    l = line([0 maxACCRate], [0 maxACCRate]);
    l.Color = 'Black';
    xlabel(baselineLevelNames{level_ind});
    ylabel(levelNames{level_ind});
    
    subplot(2, numLevels, numLevels + level_ind);
    plot(baselineObs(level_ind, getBrainArea('dlPFC')), levelObs(level_ind, getBrainArea('dlPFC')), ...
        '.', 'MarkerSize', 12, 'Color', [153, 153, 153] ./ 255);
    hold all;
    plot(baselineObs(level_ind, getBrainArea('dlPFC')), levelObs(level_ind, getBrainArea('dlPFC')) .* sigMask(level_ind, getBrainArea('dlPFC')), ...
        '.', 'MarkerSize', 12, 'Color', colorInfo(levelNames{level_ind}));
    title(sprintf('dlPFC - %s' , levelNames{level_ind}));
    text(5, maxDLPFCRate - 5, sprintf('%d / %d', nansum(sigMask(level_ind, getBrainArea('dlPFC'))), sum(getBrainArea('dlPFC'))));
    box off;
    axis square;
    set(gca, 'TickLength', [0 0]);
    set(gca, 'XTick', [0, (maxDLPFCRate / 2), maxDLPFCRate]);
    set(gca, 'YTick', [0, (maxDLPFCRate / 2), maxDLPFCRate]);
    xlim([0 maxDLPFCRate]);
    ylim([0 maxDLPFCRate]);
    l = line([0 maxDLPFCRate], [0 maxDLPFCRate]);
    l.Color = 'Black';
    xlabel(baselineLevelNames{level_ind});
    ylabel(levelNames{level_ind});
end

end
