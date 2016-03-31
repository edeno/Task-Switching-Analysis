function plotCorrAnalysis(timePeriod)
workingDir = getWorkingDir();
factorsDir = sprintf('%s/Processed Data/%s/correlationAnalysis/', workingDir, timePeriod);
factorNames = dir(factorsDir);
factorNames = {factorNames(~ismember({factorNames.name}, {'.', '..'})).name};
for factor_ind = 1:length(factorNames),
    fileNames = dir(sprintf('%s/%s/*_correlationAnalysis.mat', factorsDir, factorNames{factor_ind}));
    fileNames = {fileNames.name};
    brainAreas = {'dlPFC', 'ACC'};
    brainArea = [];
    obsDiff = [];
    neuronNames = [];
    avgFiringRate = [];
    
    for file_ind = 1:length(fileNames),
        file = load(sprintf('%s/%s/%s', factorsDir, factorNames{factor_ind}, fileNames{file_ind}));
        obsDiff = cat(3, obsDiff, file.obsDiff);
        brainArea = cat(1, brainArea, file.neuronBrainArea);
        neuronNames = cat(1, neuronNames, file.neuronNames);
        avgFiringRate = cat(2, avgFiringRate, file.avgFiringRate);
    end
    
    %%
    numLevels = size(obsDiff, 1);
    comparisonNames = file.comparisonNames;
    excludeLowFiring = avgFiringRate' > 0.5;
    
    for level_ind = 1:numLevels,
        for area_ind = 1:length(brainAreas),
            isArea = ismember(brainArea, brainAreas{area_ind});
            data = squeeze(obsDiff(level_ind, :, isArea & excludeLowFiring));
            f = figure;
            plot(data(2, :), data(1, :), '.');
            r = corr(data', 'type', 'Pearson');
            bounds = [-max(abs(data(:))) max(abs(data(:)))];
            xlim(bounds);
            ylim(bounds);
            axis square;
            vline(0, 'Color', 'black');
            hline(0, 'Color', 'black');
            l = line(bounds, bounds);
            l.Color = 'black';
            l.LineStyle = '--';
            ls = lsline;
            text(ls.XData(2), ls.YData(2), sprintf('r = %.2f', r(1,2)))
            xlabel('Baseline Orientation - Color');
            ylabel(comparisonNames{level_ind});
            f.Name = sprintf('%s - %s', brainAreas{area_ind}, comparisonNames{level_ind});
        end
    end
end
end