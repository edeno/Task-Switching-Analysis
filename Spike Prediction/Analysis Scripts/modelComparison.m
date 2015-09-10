%% Collect Model Prediction Data
clear all; close all; clc;
setMainDir;
main_dir = getenv('MAIN_DIR');
load(sprintf('%s/paramSet.mat', main_dir), 'data_info', 'validFolders', 'numTotalNeurons');

% Preallocate
timePeriodNames = validFolders;
modelDir = sprintf('%s/%s/Models', data_info.processed_dir, timePeriodNames{3});
try
    load(sprintf('%s/modelList.mat', modelDir));
    modelFile = sprintf('%s/%s/GAMpred/neurons.mat', modelDir, modelList(3).folderName);
    load(modelFile, 'validPredType');
catch
    
end

numModels = length(modelList);
numPredType = length(validPredType);
numTimePeriods = length(timePeriodNames);
meanPredError = nan(numTimePeriods, numModels, numTotalNeurons, numPredType);

for timePeriod_ind = 1:numTimePeriods,
    modelDir = sprintf('%s/%s/Models', data_info.processed_dir, timePeriodNames{timePeriod_ind});
    try
        load(sprintf('%s/modelList.mat', modelDir));
    catch
        continue;
    end
    
    for model_ind = 1:length(modelList),
        modelFile = sprintf('%s/%s/GAMpred/neurons.mat', modelDir, modelList(model_ind).folderName);
        try
            model = load(modelFile, 'neurons');
        catch
            continue;
        end
        % Average prediction error over folds
        meanPredError(timePeriod_ind, model_ind, :, :) = squeeze(nanmean([model.neurons.pred_error], 1));
    end
    
end

% Gather useful indicies and labels
isPFC = logical([model.neurons.pfc]);
monkeyNames = {model.neurons.monkey};
sessionNames = {model.neurons.file};
modelNames = {modelList.modelName};
brainAreas = {'ACC', 'dlPFC'};

%% Compare all models over brain areas
brainArea_ind = true;

figure;
predType_ind = ismember(validPredType, 'AUC');
subplot(2,2,1);
plot(squeeze(mean(meanPredError(:, :, isPFC == brainArea_ind, predType_ind), 3)), 1:numModels)
legend(timePeriodNames)
vline(0.5, 'k');
title('PFC - AUC')
% set(gca, 'YTick', 1:numModels)
% set(gca, 'YTickLabel', modelNames)
ylim([1 numModels]);

subplot(2,2,2);
predType_ind = ismember(validPredType, 'MI');
plot(squeeze(mean(meanPredError(:, :, isPFC == brainArea_ind, predType_ind), 3)), 1:numModels)
vline(0.0, 'k');
title('PFC - MI')
ylim([1 numModels]);

brainArea_ind = false;
subplot(2,2,3);
predType_ind = ismember(validPredType, 'AUC');
plot(squeeze(mean(meanPredError(:, :, isPFC == brainArea_ind, predType_ind), 3)), 1:numModels)
vline(0.5, 'k');
title('ACC - AUC')
ylim([1 numModels]);

subplot(2,2,4);
predType_ind = ismember(validPredType, 'MI');
plot(squeeze(mean(meanPredError(:, :, isPFC == brainArea_ind, predType_ind), 3)), 1:numModels)
vline(0.0, 'k');
title('ACC - MI')
ylim([1 numModels]);

%% Previous Error History over time for ACC
model_ind = find(ismember(modelNames, 'Previous Error History'));
brainArea_ind = false;
timePeriod_ind = find(ismember(timePeriodNames, {'Intertrial Interval', 'Fixation', 'Rule Stimulus', 'Stimulus Response', 'Saccade', 'Reward'}));
predType_ind = ismember(validPredType, 'MI');
meanPopMI_ACC = squeeze(mean(meanPredError(timePeriod_ind, model_ind, isPFC == brainArea_ind, predType_ind), 3));
semPopMI_ACC = squeeze(std(meanPredError(timePeriod_ind, model_ind, isPFC == brainArea_ind, predType_ind), [], 3)) / sqrt(sum(isPFC == brainArea_ind));

figure;
subplot(2,1,1);
errorbar(timePeriod_ind, meanPopMI_ACC, semPopMI_ACC)
set(gca, 'XTick', 1:length(timePeriod_ind));
set(gca, 'XTickLabel', timePeriodNames(timePeriod_ind));
ylabel('Mutual Information (bits / spike)')
hline(0, 'k');
box off;

brainArea_ind = 0;
timePeriod_ind = find(ismember(timePeriodNames, {'Intertrial Interval', 'Fixation', 'Rule Stimulus', 'Stimulus Response', 'Saccade', 'Reward'}));
predType_ind = ismember(validPredType, 'AUC');
meanPopAUC_ACC = squeeze(mean(meanPredError(timePeriod_ind, model_ind, isPFC == brainArea_ind, predType_ind), 3));
semPopAUC_ACC = squeeze(std(meanPredError(timePeriod_ind, model_ind, isPFC == brainArea_ind, predType_ind), [], 3)) / sqrt(sum(isPFC == brainArea_ind));

subplot(2,1,2);
errorbar(timePeriod_ind, meanPopAUC_ACC, semPopAUC_ACC)
set(gca, 'XTick', 1:length(timePeriod_ind));
set(gca, 'XTickLabel', timePeriodNames(timePeriod_ind));
ylabel('AUC')
hline(0.5, 'k');
box off;

suptitle('Previous Error History')

%% Previous Error History vs. Previous Congruency
modelsToCompare = {'Previous Error History', 'Previous Error History + Previous Congruency'};
model_ind = find(ismember(modelNames, modelsToCompare));
brainArea_ind = false;
timePeriod_ind = find(ismember(timePeriodNames, {'Intertrial Interval', 'Fixation', 'Rule Stimulus', 'Stimulus Response', 'Saccade', 'Reward'}));
predType_ind = ismember(validPredType, 'MI');

vsPredError = meanPredError(timePeriod_ind, model_ind, isPFC == brainArea_ind, predType_ind);
limits = quantile(vsPredError(:), [0 1]);

figure;
for time_ind = 1:length(timePeriod_ind),
   subplot(1, length(timePeriod_ind), time_ind);
   scatter(squeeze(vsPredError(time_ind, 1, :)), squeeze(vsPredError(time_ind, 2, :)));
   axis square;
   xlim(limits);
   ylim(limits);
   hline(0);
   vline(0);
   line(limits, limits);
   title(timePeriodNames(time_ind));
end
suplabel(modelsToCompare{1}, 'x');
suplabel(modelsToCompare{2}, 'y');

%% Previous Error History vs. Rule Repetition

modelsToCompare = {'Previous Error History', 'Rule Repetition + Previous Error History'};
model_ind = find(ismember(modelNames, modelsToCompare));
brainArea_ind = false;
timePeriod_ind = find(ismember(timePeriodNames, {'Intertrial Interval', 'Fixation', 'Rule Stimulus', 'Stimulus Response', 'Saccade', 'Reward'}));
predType_ind = ismember(validPredType, 'MI');

vsPredError = meanPredError(timePeriod_ind, model_ind, isPFC == brainArea_ind, predType_ind);
limits = quantile(vsPredError(:), [0 1]);

figure;
for time_ind = 1:length(timePeriod_ind),
   subplot(1, length(timePeriod_ind), time_ind);
   scatter(squeeze(vsPredError(time_ind, 1, :)), squeeze(vsPredError(time_ind, 2, :)));
   axis square;
   xlim(limits);
   ylim(limits);
   hline(0);
   vline(0);
   line(limits, limits);
   title(timePeriodNames(time_ind));
end
suplabel(modelsToCompare{1}, 'x');
suplabel(modelsToCompare{2}, 'y');

%% Previous Error History vs. Rule

modelsToCompare = {'Previous Error History', 'Rule + Previous Error History'};
model_ind = find(ismember(modelNames, modelsToCompare));
brainArea_ind = false;
timePeriod_ind = find(ismember(timePeriodNames, {'Intertrial Interval', 'Fixation', 'Rule Stimulus', 'Stimulus Response', 'Saccade', 'Reward'}));
predType_ind = ismember(validPredType, 'MI');

vsPredError = meanPredError(timePeriod_ind, model_ind, isPFC == brainArea_ind, predType_ind);
limits = quantile(vsPredError(:), [0 1]);

figure;
for time_ind = 1:length(timePeriod_ind),
   subplot(1, length(timePeriod_ind), time_ind);
   scatter(squeeze(vsPredError(time_ind, 1, :)), squeeze(vsPredError(time_ind, 2, :)));
   axis square;
   xlim(limits);
   ylim(limits);
   hline(0);
   vline(0);
   line(limits, limits);
   title(timePeriodNames(time_ind));
end
suplabel(modelsToCompare{1}, 'x');
suplabel(modelsToCompare{2}, 'y');

%%

modelsToCompare = {'Previous Error History', 'Rule * Previous Error History'};
model_ind = find(ismember(modelNames, modelsToCompare));
brainArea_ind = false;
timePeriod_ind = find(ismember(timePeriodNames, {'Intertrial Interval', 'Fixation', 'Rule Stimulus', 'Stimulus Response', 'Saccade', 'Reward'}));
predType_ind = ismember(validPredType, 'MI');

vsPredError = meanPredError(timePeriod_ind, model_ind, isPFC == brainArea_ind, predType_ind);
limits = quantile(vsPredError(:), [0 1]);

figure;
for time_ind = 1:length(timePeriod_ind),
   subplot(1, length(timePeriod_ind), time_ind);
   scatter(squeeze(vsPredError(time_ind, 1, :)), squeeze(vsPredError(time_ind, 2, :)));
   axis square;
   xlim(limits);
   ylim(limits);
   hline(0);
   vline(0);
   line(limits, limits);
   title(timePeriodNames(time_ind));
end
suplabel(modelsToCompare{1}, 'x');
suplabel(modelsToCompare{2}, 'y');

