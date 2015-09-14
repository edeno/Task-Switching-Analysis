function plotPreviousError(meanPredError, modelNames, timePeriodNames, validPredType, isPFC)

numTimePeriods = length(timePeriodNames);
subplot = @(m,n,p) subtightplot (m, n, p, [0.1 0.1], [0.1 0.1], [0.1 0.1]);
model_ind = find(ismember(modelNames, {'Previous Error History', 'Previous Error History + Response Direction'}));
meanNeurons = @(x) nanmean(x, 3);
stdErrorNeurons = @(x) nanstd(x, [], 3) / sqrt(size(x, 3));
AUC = meanPredError(:, model_ind, :, ismember(validPredType, 'AUC'));
MI = meanPredError(:, model_ind, :, ismember(validPredType, 'MI'));

figure;
subplot(2,1,1);
errorbar(1:numTimePeriods, squeeze(nansum(meanNeurons(MI), 2)), nanmean(stdErrorNeurons(MI(:, :,  isPFC == false)), 2));

set(gca, 'XTick', 1:numTimePeriods);
set(gca, 'XTickLabel', timePeriodNames);
ylabel('Mutual Information (bits / spike)')
hline(0, 'k');
box off;

subplot(2,1,2);
errorbar(1:numTimePeriods, squeeze(nansum(meanNeurons(AUC), 2)), nanmean(stdErrorNeurons(AUC(:, :,  isPFC == false)), 2));
set(gca, 'XTick', 1:numTimePeriods);
set(gca, 'XTickLabel', timePeriodNames);
ylabel('AUC')
hline(0.5, 'k');
box off;

suptitle('ACC - Previous Error History + Response Direction')
end