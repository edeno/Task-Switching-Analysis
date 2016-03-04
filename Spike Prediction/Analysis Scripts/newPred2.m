clear variables;
brainAreas = {'ACC', 'dlPFC'};
timePeriods = {'Rule Response'};
predType = {'mutualInformation', 'AUC'};
workingDir = getWorkingDir();
load(sprintf('%s/GAMFileNames.mat', workingDir), 'gamPredFileNames');
fileNames = gamPredFileNames;

for brain_ind = 1:length(brainAreas),
    for time_ind = 1:length(timePeriods),      
        timePeriod = timePeriods{time_ind};
        brainArea = brainAreas{brain_ind};
        modelsFolder = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriods{time_ind});
        load([modelsFolder, '/modelList.mat'])
        fprintf('\nTime Period: %s\n', timePeriod);
        fprintf('\nBrain Area: %s\n', brainArea);
        models = {...
            's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50)', ...
            's(Rule * Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50)', ...
            's(Rule * Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule * Rule Repetition, Trial Time, knotDiff=50)', ...
            's(Rule * Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule * Rule Repetition, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50)', ...
            };
        
        files = find(cellfun(@(x) ~isempty(x), strfind(gamPredFileNames, brainArea)));
        numModels = length(models);
        numNeurons = length(files);
        numPred = length(predType);
        pred = nan(numModels, numNeurons, numPred);
        
        for model_ind = 1:numModels,
            curFolder = sprintf('%s/%s', modelsFolder, modelList(models{model_ind}));
            fprintf('\tModel: %s\n', models{model_ind});
            count = 1;
            for file_ind = files,
                try
                    load(sprintf('%s/%s', curFolder, fileNames{file_ind}), 'neuron');
                    fprintf('\t\t...%s\n', fileNames{file_ind});
                    for pred_ind = 1:numPred,
                        pred(model_ind, count, pred_ind) = nanmean(neuron.(predType{pred_ind}));
                    end
                catch
                end
                count = count + 1;
            end
        end   
        fprintf('\nSaving...\n');
        neuronNames = strrep(fileNames(files), '_GAMpred.mat', '');
        saveFileName = sprintf('%s/Spike Prediction/pred_%s_%s_spline.mat', workingDir, brainArea, timePeriods{time_ind});
        save(saveFileName, 'timePeriod', 'brainArea', 'models', 'numModels', 'numNeurons', 'numPred', 'predType', 'pred', 'neuronNames');       
    end
end
