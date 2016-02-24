clear variables
brainAreas = {'ACC', 'dlPFC'};
timePeriods = {'Rule Response', 'Stimulus Reward'};
predType = {'mutualInformation', 'AUC', 'Dev'};

for brain_ind = 1:length(brainAreas),
for time_ind = 1:length(timePeriods),
    
timePeriod = timePeriods{time_ind};
brainArea = brainAreas{brain_ind};
modelsFolder = sprintf('/data/home/edeno/Task-Switching-Analysis/Processed Data/%s/Models/', timePeriods{time_ind});
load([modelsFolder, '/modelList.mat'])

models = {...
    'Constant', ...
    'Previous Error + Response Direction', ...
    'Previous Error + Response Direction + Rule Repetition', ...
    'Previous Error + Response Direction + Congruency', ...
    'Previous Error + Response Direction + Rule Repetition + Congruency', ...
    'Previous Error + Response Direction + Rule', ...
    'Previous Error + Response Direction + Rule Repetition + Rule', ...
    'Previous Error + Response Direction + Congruency + Rule', ...
    'Previous Error + Response Direction + Rule Repetition + Congruency + Rule', ...
    'Rule * Previous Error + Response Direction', ...
    'Rule * Previous Error + Response Direction + Rule * Rule Repetition', ...
    'Rule * Previous Error + Response Direction + Rule * Congruency', ...
    'Rule * Previous Error + Response Direction + Rule * Rule Repetition + Rule * Congruency', ...
    };

numModels = length(models);
numNeurons = length(dir(sprintf('%s/%s/%s*GAMpred.mat', modelsFolder, modelList('Constant'), brainArea)));
numPred = length(predType);
pred = nan(numModels, numNeurons, numPred);

for model_ind = 1:numModels,
    curFolder = sprintf('%s/%s', modelsFolder, modelList(models{model_ind}));
    
    fileNames = dir(sprintf('%s/%s*GAMpred.mat', curFolder, brainArea));
    fileNames = {fileNames.name};
    
    for file_ind = 1:numNeurons,
        load(sprintf('%s/%s', curFolder, fileNames{file_ind}), 'neuron');
        for pred_ind = 1:numPred,
          pred(model_ind, file_ind, pred_ind) = nanmean(neuron.(predType{pred_ind}));
        end
    end
    
end

save(['pred_', brainArea, '_', timePeriods{time_ind}, '_constant', '.mat']);

end
end
