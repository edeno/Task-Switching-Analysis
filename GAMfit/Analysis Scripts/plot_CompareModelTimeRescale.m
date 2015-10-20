function plot_CompareModelTimeRescale(brainArea, timePeriod, plotType)
% Models to compare
mainDir = getWorkingDir();
modelDir = sprintf('%s/Processed Data/%s/Models/', mainDir, timePeriod);

load(sprintf('%s/modelList.mat', modelDir));
models = modelList.keys;
timeRescale = cell(size(models));

neurons = load(sprintf('%s/%s/Collected GAMfit/neurons.mat', modelDir, modelList(models{1})));
brainAreas = {neurons.neurons.brainArea};
monkeyNames = upper({neurons.neurons.monkey});

clear neurons;

for file_ind = 1:length(models),
    statsFile = load(sprintf('%s/%s/Collected GAMfit/stats.mat', modelDir, modelList(models{file_ind})));
    timeRescale{file_ind} = [statsFile.stats.timeRescale];
end

clear statsFile;

plotMap = containers.Map;
plotMap('Q-Q Plot') = @plotQQ;
plotMap('KS Difference') = @plotKSdiff;
plotMap('KS Stat') = @plotKSstat;
plotMap('KS Stat Difference') = @plotKSstatDiff;

plotFun = plotMap(plotType);

subplot_ind = allcomb(1:length(models), 1:length(models));
filter_ind = ismember(brainAreas, brainArea);

figure;
if ~strcmp(plotType, 'KS Stat Difference'),
    for comparison_ind = 1:length(subplot_ind),
        model1_ind = subplot_ind(comparison_ind, 1);
        model2_ind = subplot_ind(comparison_ind, 2);
        
        subplot(length(models), length(models), comparison_ind);
        if model1_ind ~= model2_ind,
            [plotHandle1] = plotFun(timeRescale{model1_ind}(filter_ind), 'b');
            [plotHandle2] = plotFun(timeRescale{model2_ind}(filter_ind), 'r');
        end
        box off;
        if model2_ind == 1,
            y = ylabel(models{model1_ind});
            y.FontSize = 5;
            y.HorizontalAlignment = 'right';
            y.Rotation = 0;
            y.Color = 'r';
        end
        if model1_ind == length(models),
            x = xlabel(models{model2_ind});
            x.FontSize = 5;
            x.Color = 'b';
        end
    end
    suptitle(sprintf('%s: %s', plotType, brainArea));
else
    for comparison_ind = 1:length(subplot_ind),
        model1_ind = subplot_ind(comparison_ind, 1);
        model2_ind = subplot_ind(comparison_ind, 2);
        
        subplot(length(models), length(models), comparison_ind);
        if model1_ind ~= model2_ind,
            [plotHandle1] = plotFun(timeRescale{model1_ind}(filter_ind), timeRescale{model2_ind}(filter_ind));
        end
        box off;
        
        if model2_ind == 1,
            y = ylabel(models{model1_ind});
            y.FontSize = 5;
            y.HorizontalAlignment = 'right';
            y.Rotation = 0;
        end
        if model1_ind == length(models),
            x = xlabel(models{model2_ind});
            x.FontSize = 5;
        end
    end
    suptitle(sprintf('%s: %s', plotType, brainArea));
    
end

end

function [KS_handle, xlab, ylab] = plotKSdiff(timeRescale, color)
for neuronInd = 1:length(timeRescale),
    uniformCDFvalues = timeRescale(neuronInd).uniformCDFvalues;
    sortedKS = timeRescale(neuronInd).sortedKS;
    KS_handle = plot(uniformCDFvalues, sortedKS - uniformCDFvalues, 'color', color); hold all;
    
end
hline(0, 'k-');
ylab = 'Model CDF - Empirical CDF';
xlab = 'Quantiles';
end

function [QQ_handle, xlab, ylab] = plotQQ(timeRescale, color)
for neuronInd = 1:length(timeRescale),
    uniformCDFvalues = timeRescale(neuronInd).uniformCDFvalues;
    rescaledISIs = sort(timeRescale(neuronInd).rescaledISIs, 'ascend');
    QQ_handle = plot(rescaledISIs, expinv(uniformCDFvalues), '-', 'color', color); hold all;
end
ylab = 'Expected Theorectical ISI Quantiles';
xlab = 'Observed ISI Quantiles';
lineHandle = line([0 max(rescaledISIs)], [0 max(rescaledISIs)]);
lineHandle.Color = 'black';
axis([0 max(rescaledISIs) 0 max(rescaledISIs)]);
end

function [ksStat_handle] = plotKSstat(timeRescale, color)
ksStat = [timeRescale.ksStat];
ksStat_handle = histogram(ksStat, 'Normalization', 'probability', 'DisplayStyle', 'stairs');
hold all;
alpha(0.5);
ylim([0 1]);
vline(median(ksStat), color)

ksStat_handle.EdgeColor = color;
end

function [ksStatDiff_handle] = plotKSstatDiff(timeRescale1, timeRescale2)
ksStatDiff = [timeRescale1.ksStat] - [timeRescale2.ksStat];
ksStatDiff_handle = histogram(ksStatDiff, 'Normalization', 'probability');
vline(0);
xlim([-0.05 0.05]);
end
