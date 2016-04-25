function plotSingleNeuronModel(neuronName, covOfInterest, timePeriod, model)
splitName = strsplit(neuronName, '-');
sessionName = splitName{1};

workingDir = getWorkingDir();
modelsDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
load(sprintf('%s/modelList.mat', modelsDir));
load(sprintf('%s/%s/%s_GAMfit.mat', modelsDir, modelList(model), sessionName), 'gamParams');

[meanSpiking, time, spikesSample, cInfo] = getSingleNeuronData(neuronName, timePeriod, covOfInterest, ...
    'includeFixationBreaks', logical(gamParams.includeFixationBreaks), ...
    'includeIncorrect', logical(gamParams.includeIncorrect), ...
    'includeTimeBeforeZero', logical(gamParams.includeTimeBeforeZero));
numSamples = max(spikesSample{1}(:, 2));

figure;
subplot(4,1,1);
plotHandle = plot(time, meanSpiking);
subplot(4,1,2);
for level_ind = 1:length(cInfo.levels),
    plot(spikesSample{level_ind}(:, 1), ((level_ind - 1) * numSamples) + spikesSample{level_ind}(:, 2), '.', 'Color', plotHandle(level_ind).Color);
    hold all;
end

%%
[meanSpiking, time, spikesSample, cInfo] = getModelSim(neuronName, timePeriod, model, covOfInterest, ...
    'includeFixationBreaks', logical(gamParams.includeFixationBreaks), ...
    'includeIncorrect', logical(gamParams.includeIncorrect), ...
    'includeTimeBeforeZero', logical(gamParams.includeTimeBeforeZero));
subplot(4,1,3);
plotHandle = plot(time, meanSpiking);
subplot(4,1,4);
for level_ind = 1:length(cInfo.levels),
    plot(spikesSample{level_ind}(:, 1), ((level_ind - 1) * numSamples) + spikesSample{level_ind}(:, 2), '.', 'Color', plotHandle(level_ind).Color);
    hold all;
end
end