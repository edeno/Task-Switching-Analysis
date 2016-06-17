load('paramSet.mat', 'colorInfo');
numLevels = length(levelNames);
numThresh = length(params.thresholds);

for area_ind = 1:length(brainAreas),
    areaData = cat(3, bootPercentGreaterThanThresh{area_ind, :});
    f = figure;
    f.Name = brainAreas{area_ind};
    sub = numSubplots(numLevels);
    for level_ind = 1:numLevels,
        subplot(sub(1), sub(2), level_ind)
        data = squeeze(areaData(level_ind, :, :));
        plot(params.thresholds, data(2, :),  '.', 'Color', colorInfo(levelNames{level_ind}), 'MarkerSize', 10);
        hold all;
%         plot(params.thresholds, data(2, :),  '-', 'Color', colorInfo(levelNames{ind}), 'LineWidth', 2);
        l = line(repmat(params.thresholds, [2, 1]), data([1 3], :));
        set(l, 'Color', colorInfo(levelNames{level_ind}));
        set(l, 'LineWidth', 1);
        title(levelNames{level_ind});
        ylim([0 100]);
        box off;
        xlabel('Percent Change in Firing Rate Threshold');
        ylabel('Percentage of Neurons > Threshold');
    end
end

%%
load('paramSet.mat', 'colorInfo');
numLevels = length(levelNames);
numThresh = length(params.thresholds);

flipNeg_ind = [(numThresh / 2):-1:1, (numThresh / 2)+1:numThresh];
flipNeg_thresholds = [params.thresholds((numThresh / 2)+1:numThresh), params.thresholds((numThresh / 2)+1:numThresh)];

for area_ind = 1:length(brainAreas),
    areaData = cat(3, bootPercentGreaterThanThresh{area_ind, :});
    f = figure;
    f.Name = brainAreas{area_ind};
    sub = numSubplots(numLevels);
    for level_ind = 1:numLevels,
        subplot(sub(1), sub(2), level_ind)
        data = squeeze(areaData(level_ind, :, :));
        l = line(repmat(flipNeg_thresholds, [2, 1]), data([1 3], flipNeg_ind));
        set(l, 'Color', colorInfo(levelNames{level_ind}));
        set(l, 'LineWidth', 0.5);
        hold all;
        plot(flipNeg_thresholds(1:(numThresh / 2)), data(2, flipNeg_ind(1:(numThresh / 2))),  '--', ...
            'Color', colorInfo(levelNames{level_ind}), 'lineWidth', 3);
        
        plot(flipNeg_thresholds((numThresh / 2)+1:end), data(2, flipNeg_ind((numThresh / 2)+1:end)),  '-', ...
            'Color', colorInfo(levelNames{level_ind}), 'lineWidth', 3);
        posNeg_sig = comparePosNeg(:, level_ind, 1, area_ind) > 0 | comparePosNeg(:, level_ind, 3, area_ind) < 0;
        posNeg_sig = double(posNeg_sig)';
        posNeg_sig(posNeg_sig == 0) = NaN;
        plot(flipNeg_thresholds((numThresh / 2)+1:end), 10 + (data(2, flipNeg_ind((numThresh / 2)+1:end)) .* posNeg_sig) ,  '*', ...
            'Color', 'black', 'markerSize', 2.5);
        title(levelNames{level_ind});
        ylim([0 100]);
        box off;
        xlabel('Percent Change in Firing Rate Threshold');
        ylabel('Percentage of Neurons > Threshold');
    end
end