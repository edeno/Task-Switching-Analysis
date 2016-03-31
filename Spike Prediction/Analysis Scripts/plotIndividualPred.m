function plotIndividualPred(model, timePeriod)

workingDir = getWorkingDir();
modelsDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
load(sprintf('%s/modelList.mat', modelsDir));

brainAreas = {'dlPFC', 'ACC'};
monkeyNames = {'', 'cc', 'isa'};
predTypes = {'mutualInformation', 'AUC'};

for pred_ind = 1:length(predTypes),
    figure;
    for area_ind = 1:length(brainAreas),
        for monkey_ind = 1:length(monkeyNames),
            
            neuronFiles = sprintf('%s/%s/%s_neuron_%s*_GAMpred.mat', modelsDir, modelList(model), brainAreas{area_ind}, monkeyNames{monkey_ind});
            
            neuronFiles = dir(neuronFiles);
            neuronFiles = {neuronFiles.name};
            
            predMetric = nan(1, length(neuronFiles));
            
            for file_ind = 1:length(neuronFiles),
                file = load(sprintf('%s/%s/%s', modelsDir, modelList(model), neuronFiles{file_ind}), 'neuron');
                predMetric(file_ind) = nanmean(file.neuron.(predTypes{pred_ind}));
            end
            
            subplot(3, 2, ( 2 * monkey_ind) - 1 + (area_ind - 1));
            hist(predMetric, 50)
            vline(mean(predMetric), 'Label', sprintf('%.2f', mean(predMetric)));
            if ~strcmp(monkeyNames{monkey_ind}, '')
                titleName = sprintf('%s: Monkey %s', brainAreas{area_ind}, monkeyNames{monkey_ind});
            else
                titleName = sprintf('%s: All Monkeys', brainAreas{area_ind});
            end
            xlabel(predTypes{pred_ind});
            title(titleName);
        end
    end
    
    suptitle(sprintf('Model: %s\nTime Period: %s', model, timePeriod));
end
end