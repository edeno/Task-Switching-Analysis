%% Collect Model Prediction Data
clear all; close all; clc;
setMainDir;
main_dir = getenv('MAIN_DIR');
load(sprintf('%s/paramSet.mat', main_dir), 'data_info', 'validFolders', ...
    'numTotalNeurons', 'validPredType');

% Preallocate
timePeriodNames = validFolders(~ismember(validFolders, {'Rule Response', 'Entire Trial'}));
modelNames = [];

% Figure out model names
for timePeriod_ind = 1:length(timePeriodNames),
    try
        load(sprintf('%s/%s/Models/modelList.mat', data_info.processed_dir, timePeriodNames{timePeriod_ind}));
        modelNames = [modelNames {modelList.modelName}];
    catch
        continue;
    end
end
modelNames = unique(modelNames, 'stable');

numModels = length(modelNames);
numPredType = length(validPredType);
numTimePeriods = length(timePeriodNames);
meanPredError = nan(numTimePeriods, numModels, numTotalNeurons, numPredType);

for timePeriod_ind = 1:numTimePeriods,
    fprintf('\nTime Period: %s\n', timePeriodNames{timePeriod_ind});
    modelDir = sprintf('%s/%s/Models', data_info.processed_dir, timePeriodNames{timePeriod_ind});
    try
        load(sprintf('%s/modelList.mat', modelDir));
    catch
        continue;
    end
    
    for model_ind = 1:length(modelList),
        fprintf('\tModel: %s\n', modelList(model_ind).modelName);
        modelFile = sprintf('%s/%s/GAMpred/neurons.mat', modelDir, modelList(model_ind).folderName);
        try
            model = load(modelFile, 'neurons');
        catch
            continue;
        end
        modelName_ind = ismember(modelNames, modelList(model_ind).modelName);
        % Average prediction error over folds
        meanPredError(timePeriod_ind, modelName_ind, :, :) = squeeze(nanmean([model.neurons.pred_error], 1));
    end
end

% Gather useful indicies and labels
isPFC = logical([model.neurons.pfc]);
monkeyNames = {model.neurons.monkey};
sessionNames = {model.neurons.file};
brainAreas = {'ACC', 'dlPFC'};

%% Compare all models over brain areas
plotModelFit_byBrainArea(meanPredError, timePeriodNames, modelNames, validPredType, isPFC)
%% Previous Error History over time for ACC
plotPreviousError(meanPredError, modelNames, timePeriodNames, validPredType, isPFC)
%% Previous Error History vs. Previous Congruency - ACC
modelsToCompare = {'Previous Error History', 'Previous Error History + Previous Congruency', ...
    'Previous Error History + Response Direction', 'Congruency History + Previous Error History + Response Direction'};
predType = 'AUC';
brainArea = 'ACC';

plotCompareTwoModels(modelsToCompare, meanPredError, predType, isPFC, modelNames, timePeriodNames, validPredType, brainArea)

%% Previous Error History vs. Rule Repetition

modelsToCompare = {'Previous Error History', 'Rule Repetition + Previous Error History', ...
    'Previous Error History + Response Direction', 'Rule Repetition + Previous Error History + Response Direction'};
predType = 'AUC';
brainArea = 'ACC';

plotCompareTwoModels(modelsToCompare, meanPredError, predType, isPFC, modelNames, timePeriodNames, validPredType, brainArea)

%% Previous Error History vs. Rule

modelsToCompare = {'Previous Error History', 'Rule + Previous Error History', ...
    'Previous Error History + Response Direction', 'Rule + Previous Error History + Response Direction'};
predType = 'AUC';
brainArea = 'ACC';

plotCompareTwoModels(modelsToCompare, meanPredError, predType, isPFC, modelNames, timePeriodNames, validPredType, brainArea)


