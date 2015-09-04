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

%%
brainArea_ind = 1;

figure;
predType_ind = ismember(validPredType, 'AUC');
subplot(2,2,1);
plot(squeeze(mean(meanPredError(:, :, isPFC == brainArea_ind, predType_ind), 3))')
legend(timePeriodNames)
hline(0.5, 'k');
title('PFC - AUC')
xlim([1 numModels]);

subplot(2,2,2);
predType_ind = ismember(validPredType, 'MI');
plot(squeeze(mean(meanPredError(:, :, isPFC == brainArea_ind, predType_ind), 3))')
hline(0.0, 'k');
title('PFC - MI')
xlim([1 numModels]);

brainArea_ind = 0;
subplot(2,2,3);
predType_ind = ismember(validPredType, 'AUC');
plot(squeeze(mean(meanPredError(:, :, isPFC == brainArea_ind, predType_ind), 3))')
hline(0.5, 'k');
title('ACC - AUC')
xlim([1 numModels]);

subplot(2,2,4);
predType_ind = ismember(validPredType, 'MI');
plot(squeeze(mean(meanPredError(:, :, isPFC == brainArea_ind, predType_ind), 3))')
hline(0.0, 'k');
title('ACC - MI')
xlim([1 numModels]);