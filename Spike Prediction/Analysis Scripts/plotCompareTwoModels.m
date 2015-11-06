function plotCompareTwoModels(modelsToCompare, meanPredError, predType, isPFC, modelNames, timePeriodNames, validPredType, brainArea)

numTimePeriods = length(timePeriodNames);
model_ind = ismember(modelNames, modelsToCompare);
predType_ind = ismember(validPredType, predType);
subplot = @(m,n,p) subtightplot (m, n, p, [0.09 0.09], [0.1 0.1], [0.1 0.1]);

vsPredError = meanPredError(:, model_ind, isPFC == strcmp(brainArea, 'dlPFC'), predType_ind);

figure;
for time_ind = 1:numTimePeriods,
    subplot(2, 3, time_ind);
    if ismember(timePeriodNames{time_ind}, {'Intertrial Interval', 'Fixation','Rule Stimulus'}),
        scatter(squeeze(vsPredError(time_ind, 1, :)), squeeze(vsPredError(time_ind, 2, :)));
    else
        scatter(squeeze(vsPredError(time_ind, 3, :)), squeeze(vsPredError(time_ind, 4, :)));
    end
    axis square;
    
    switch predType
        case 'MI'
            limits = [-1 1];
            xlim(limits);
            ylim(limits);
            hline(0);
            vline(0);
        case 'AUC'
            limits = [0.45 0.7];
            xlim(limits);
            ylim(limits);
            hline(0.5);
            vline(0.5);
        otherwise
            limits = [0 1];
            xlim(limits);
            ylim(limits);
    end
    line(limits, limits);
    title(timePeriodNames(time_ind));
end
suplabel(modelsToCompare{3}, 'x',  [.08 .1 .84 .84]);
suplabel(modelsToCompare{4}, 'y', [.1 .08 .84 .84]);
suptitle(sprintf('%s: %s', brainArea, predType))

end