clear variables
brainAreas = {'ACC', 'dlPFC'};
timePeriods = {'Rule Response'};
predType = {'mutualInformation', 'AUC', 'Dev'};
workingDir = getWorkingDir();

for brain_ind = 1:length(brainAreas),
for time_ind = 1:length(timePeriods),
    
timePeriod = timePeriods{time_ind};
brainArea = brainAreas{brain_ind};
modelsFolder = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriods{time_ind});
load([modelsFolder, '/modelList.mat'])

models = {...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50)', ...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50)', ...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule, Trial Time, knotDiff=50)', ...
    };

numModels = length(models);
fileNames = dir(sprintf('%s/%s/%s*GAMpred.mat', modelsFolder, modelList('Constant'), brainArea));
fileNames = {fileNames.name};
numNeurons = length(fileNames);
numPred = length(predType);
pred = nan(numModels, numNeurons, numPred);

for model_ind = 1:numModels,
    curFolder = sprintf('%s/%s', modelsFolder, modelList(models{model_ind}));
    
    for file_ind = 1:numNeurons,
        try
        load(sprintf('%s/%s', curFolder, fileNames{file_ind}), 'neuron');
        for pred_ind = 1:numPred,
          pred(model_ind, file_ind, pred_ind) = nanmean(neuron.(predType{pred_ind}));
        end
        catch
        end
    end
    
end

saveFileName = sprintf('%s/Spike Prediction/pred_%s_%s_spline.mat', workingDir, brainArea, timePeriods{time_ind});
save(saveFileName);

end
end
