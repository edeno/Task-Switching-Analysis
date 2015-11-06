function plotModelFit_byBrainArea(meanPredError, timePeriodNames, modelNames, validPredType, isPFC)
numModels = length(modelNames);
numTimePeriods = length(timePeriodNames);

subplot = @(m,n,p) subtightplot (m, n, p, [0.1 0.02], [0.1 0.1], [0.4 0.02]);
meanNeurons = @(x) nanmean(x, 3);
stdErrorNeurons = @(x) nanstd(x, [], 3) / sqrt(size(x, 3));
err = @(x) [meanNeurons(x) - stdErrorNeurons(x); meanNeurons(x) + stdErrorNeurons(x)];
AUC = meanPredError(:, :, :, ismember(validPredType, 'AUC'));
MI = meanPredError(:, :, :, ismember(validPredType, 'MI'));
AIC = meanPredError(:, :, :, ismember(validPredType, 'AIC'));

colorOrder = get(0, 'DefaultAxesColorOrder');

figure;

subplot(2,3,1);
for timePeriod_ind = 1:numTimePeriods,
    plotHandle(timePeriod_ind) = plot(meanNeurons(AUC(timePeriod_ind, :, isPFC == true)), 1:numModels, ...
        '.-', ...
        'MarkerSize', 20, ...
        'Color', colorOrder(timePeriod_ind, :));
    hold all;
    line(err(AUC(timePeriod_ind, :, isPFC == true)), repmat(1:numModels, [2 1]), ...
        'Color', colorOrder(timePeriod_ind, :), ...
        'LineWidth', 2);
end

vline(0.5, 'k');
title('PFC - AUC')
set(gca, 'YTick', 1:numModels)
set(gca, 'YTickLabel', modelNames)
set(gca, 'FontSize', 10);
box off;
ylim([1 numModels]);
xlim([0.5 0.65]);
set(gca, 'YGrid', 'on')

subplot(2,3,2);
for timePeriod_ind = 1:numTimePeriods,
    plotHandle(timePeriod_ind) = plot(meanNeurons(MI(timePeriod_ind, :, isPFC == true)), 1:numModels, ...
        '.-', ...
        'MarkerSize', 20, ...
        'Color', colorOrder(timePeriod_ind, :));
    hold all;
    line(err(MI(timePeriod_ind, :, isPFC == true)), repmat(1:numModels, [2 1]), ...
        'Color', colorOrder(timePeriod_ind, :), ...
        'LineWidth', 2);
end
vline(0.0, 'k');
box off;
title('PFC - MI')
set(gca, 'YTick', 1:numModels)
set(gca, 'YTickLabel', [])
set(gca, 'FontSize', 10);
ylim([1 numModels]);
xlim([-1 1]);
set(gca, 'YGrid', 'on')

subplot(2,3,3);
for timePeriod_ind = 1:numTimePeriods,
    plotHandle(timePeriod_ind) = plot(meanNeurons(computeAICWeights(AIC(timePeriod_ind, :, isPFC == true), 2)), 1:numModels, ...
        '.-', ...
        'MarkerSize', 20, ...
        'Color', colorOrder(timePeriod_ind, :));
    hold all;
    line(err(computeAICWeights(AIC(timePeriod_ind, :, isPFC == true), 2)), repmat(1:numModels, [2 1]), ...
        'Color', colorOrder(timePeriod_ind, :), ...
        'LineWidth', 2);
end

vline(0.0, 'k');
box off;
title('PFC - Weighted AIC')
legend(plotHandle, timePeriodNames)
set(gca, 'YTick', 1:numModels)
set(gca, 'YTickLabel', [])
set(gca, 'FontSize', 10);
ylim([1 numModels]);
xlim([0 1]);
set(gca, 'YGrid', 'on')

subplot(2,3,4);
for timePeriod_ind = 1:numTimePeriods,
    plotHandle(timePeriod_ind) = plot(meanNeurons(AUC(timePeriod_ind, :, isPFC == false)), 1:numModels, ...
        '.-', ...
        'MarkerSize', 20, ...
        'Color', colorOrder(timePeriod_ind, :));
    hold all;
    line(err(AUC(timePeriod_ind, :, isPFC == false)), repmat(1:numModels, [2 1]), ...
        'Color', colorOrder(timePeriod_ind, :), ...
        'LineWidth', 2);
end
vline(0.5, 'k');
title('ACC - AUC')
box off;
ylim([1 numModels]);
set(gca, 'FontSize', 10);
xlim([0.5 0.65]);
set(gca, 'YTick', 1:numModels)
set(gca, 'YTickLabel', modelNames)
set(gca, 'YGrid', 'on')

subplot(2,3,5);
for timePeriod_ind = 1:numTimePeriods,
    plotHandle(timePeriod_ind) = plot(meanNeurons(MI(timePeriod_ind, :, isPFC == false)), 1:numModels, ...
        '.-', ...
        'MarkerSize', 20, ...
        'Color', colorOrder(timePeriod_ind, :));
    hold all;
    line(err(MI(timePeriod_ind, :, isPFC == false)), repmat(1:numModels, [2 1]), ...
        'Color', colorOrder(timePeriod_ind, :), ...
        'LineWidth', 2);
end
vline(0.0, 'k');
box off;
title('ACC - MI')
set(gca, 'YTick', 1:numModels)
set(gca, 'YTickLabel', [])
set(gca, 'FontSize', 10);
ylim([1 numModels]);
xlim([-1 1]);
set(gca, 'YGrid', 'on')


subplot(2,3,6);
for timePeriod_ind = 1:numTimePeriods,
    plotHandle(timePeriod_ind) = plot(meanNeurons(computeAICWeights(AIC(timePeriod_ind, :, isPFC == false), 2)), 1:numModels, ...
        '.-', ...
        'MarkerSize', 20, ...
        'Color', colorOrder(timePeriod_ind, :));
    hold all;
    line(err(computeAICWeights(AIC(timePeriod_ind, :, isPFC == false), 2)), repmat(1:numModels, [2 1]), ...
        'Color', colorOrder(timePeriod_ind, :), ...
        'LineWidth', 2)
end

vline(0.0, 'k');
box off;
title('ACC - Weighted AIC')
set(gca, 'YTick', 1:numModels)
set(gca, 'YTickLabel', [])
set(gca, 'FontSize', 10);
ylim([1 numModels]);
xlim([0 1]);
set(gca, 'YGrid', 'on')

end