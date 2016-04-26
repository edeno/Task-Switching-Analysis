function plotSingleNeuronModel(neuronName, covOfInterest, timePeriod, model)
splitName = strsplit(neuronName, '-');
sessionName = splitName{1};

workingDir = getWorkingDir();
modelsDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
mL = load(sprintf('%s/modelList.mat', modelsDir));
modelList = mL.modelList;
gP = load(sprintf('%s/%s/%s_GAMfit.mat', modelsDir, modelList(model), sessionName), 'gamParams');
gamParams = gP.gamParams;

[meanSpiking, time, spikesSample, cInfo] = getSingleNeuronData(neuronName, timePeriod, covOfInterest, ...
    'includeFixationBreaks', logical(gamParams.includeFixationBreaks), ...
    'includeIncorrect', logical(gamParams.includeIncorrect), ...
    'includeTimeBeforeZero', logical(gamParams.includeTimeBeforeZero));
numSamples = max(spikesSample{1}(:, 2));

f = figure;
f.Name = sprintf('%s - %s - %s', neuronName, timePeriod, covOfInterest);
s1 = subplot(4,1,1);
[plotHandle1] = plotMeanRate();
legend(cInfo.levels);
set(gca, 'XTickLabel', [])
title('PSTH from Data');

subplot(4,1,2);
plotRaster(plotHandle1);
set(gca, 'XTickLabel', [])
title('Spikes');
%%
[meanSpiking, time, spikesSample, cInfo] = getModelSim(neuronName, timePeriod, model, covOfInterest, ...
    'includeFixationBreaks', logical(gamParams.includeFixationBreaks), ...
    'includeIncorrect', logical(gamParams.includeIncorrect), ...
    'includeTimeBeforeZero', logical(gamParams.includeTimeBeforeZero));
s2 = subplot(4,1,3);
[plotHandle2] = plotMeanRate();
set(gca, 'XTickLabel', [])
title('Model Estimated PSTH');

subplot(4,1,4);
plotRaster(plotHandle2);
xlabel('Time (ms)');
title('Model Estimated Spikes');

set([s1, s2], 'YLim', [0, max([s1.YLim, s2.YLim])])

    function [plotHandle] = plotMeanRate()
        plotHandle = plot(time, meanSpiking);
        xlim(quantile(time, [0 1]));
        box off;
        set(gca, 'TickLength', [0, 0]);
        vline(0, 'Color', 'black', 'LineType', '-');
        ylabel('Spikes / s');
    end

    function plotRaster(plotHandle)
        for level_ind = 1:length(cInfo.levels),
            plot(spikesSample{level_ind}(:, 1), ((level_ind - 1) * numSamples) + spikesSample{level_ind}(:, 2), '.', 'Color', plotHandle(level_ind).Color, 'LineWidth', 2);
            xlim(quantile(time, [0 1]));
            set(gca, 'TickLength', [0, 0]);
            set(gca, 'YTickLabel', [])
            box off;
            vline(0, 'Color', 'black', 'LineType', '-');
            hold all;
            ylabel('Trials');
        end
    end

end