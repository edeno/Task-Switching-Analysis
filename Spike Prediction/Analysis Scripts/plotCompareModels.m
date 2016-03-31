function plotCompareModels(models, timePeriod)
workingDir = getWorkingDir();
modelsDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
m = load(sprintf('%s/modelList.mat', modelsDir));
modelList = m.modelList;
numModels = length(models);

brainAreas = {'dlPFC', 'ACC'};
monkeyNames = {'cc', 'isa'};
predTypes = {'AUC'};
saveDir = sprintf('%s/Figures/%s/', workingDir, timePeriod);
if ~exist(saveDir, 'dir'),
    mkdir(saveDir);
end

for pred_ind = 1:length(predTypes),
    for area_ind = 1:length(brainAreas),
        f = figure;
        count = 1;
        axisHandle = tight_subplot(numModels, numModels, [0.02 0.01]);
        for model1_ind = 1:numModels,
            pred1 = getPredMetric(model1_ind);
            for model2_ind = 1:numModels,
                axes(axisHandle(count));
                if (model1_ind == model2_ind),
                    h = histogram(pred1, 'BinWidth', .01, 'Normalization', 'probability');
                    t = title(models{model1_ind});
                    t.FontSize = 8;
                    xlim([0.4 0.8]);
                    vline(0.5);
                else
                    pred2 = getPredMetric(model2_ind);
                    plot(pred2, pred1, '.');
                    bounds = [0.4 0.8];
                    xlim(bounds); ylim(bounds);
                    l = line(bounds, bounds);
                    l.Color = 'Black';
                    t1 = text(bounds(1), bounds(2), models{model1_ind});
                    t1.FontSize = 5;
                    t1.VerticalAlignment = 'top';
                    t2 = text(bounds(2), bounds(1), models{model2_ind});
                    t2.HorizontalAlignment = 'right';
                    t2.VerticalAlignment = 'bottom';
                    t2.FontSize = 5;
                end
                
                if (model1_ind ~= numModels) || (model2_ind ~= 1)
                    set(gca, 'XTickLabel', []);
                    set(gca, 'YTickLabel', []);
                end
                
                count = count + 1;
            end
        end
        f.Name = sprintf('%s - %s - %s', timePeriod, brainAreas{area_ind}, predTypes{pred_ind});
        saveName = sprintf('%s/%s_%s_%s_All Models', saveDir, timePeriod, brainAreas{area_ind}, predTypes{pred_ind});
        saveas(f, saveName)
        %% Best Model
        pred = nan(numModels + 1, size(pred1, 2));
        for model_ind = 1:numModels,
            pred(model_ind, :) = getPredMetric(model_ind);
        end
        pred(end, :) = 0.5;
        
        
        [~, max_ind] = max(pred);
        f = figure;
        subplot(2,1,1);
        h = histogram(max_ind);
        h.Orientation = 'horizontal';
        h.Normalization = 'pdf';
        set(gca, 'YTick', 1:(numModels + 1));
        set(gca, 'YTickLabel', [models, {'Constant'}]);
        
        
        subplot(2,1,2);
        plot(mean(pred, 2), 1:(numModels + 1), '.-', 'MarkerSize', 30)
        set(gca, 'YTick', 1:(numModels + 1));
        set(gca, 'YTickLabel', [models, {'Constant'}]);
        grid on;
        f.Name = sprintf('%s - %s - %s - Best Model', timePeriod, brainAreas{area_ind}, predTypes{pred_ind});
        saveName = sprintf('%s/%s_%s_%s_Best Model', saveDir, timePeriod, brainAreas{area_ind}, predTypes{pred_ind});
        saveas(f, saveName)
    end
end

    function [predMetric] = getPredMetric(model_ind)
        neuronFiles = sprintf('%s/%s/%s_neuron_*_GAMpred.mat', modelsDir, modelList(models{model_ind}), brainAreas{area_ind});
        
        neuronFiles = dir(neuronFiles);
        neuronFiles = {neuronFiles.name};
        
        predMetric = nan(1, length(neuronFiles));
        
        for file_ind = 1:length(neuronFiles),
            file = load(sprintf('%s/%s/%s', modelsDir, modelList(models{model_ind}), neuronFiles{file_ind}), 'neuron');
            predMetric(file_ind) = nanmean(file.neuron.(predTypes{pred_ind}));
        end
    end
end