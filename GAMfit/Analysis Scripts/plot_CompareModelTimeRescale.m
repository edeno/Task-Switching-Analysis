function plot_CompareModelTimeRescale(model1, model2, brainArea)
% Models to compare
mainDir = getWorkingDir();
timePeriod = 'Rule Response';
modelDir = sprintf('%s/Processed Data/%s/Models/', mainDir, timePeriod);

load(sprintf('%s/modelList.mat', modelDir));

statsFile1 = load(sprintf('%s/%s/Collected GAMfit/stats.mat', modelDir, modelList(model1)));
statsFile2 = load(sprintf('%s/%s/Collected GAMfit/stats.mat', modelDir, modelList(model2)));

timeRescale1 = [statsFile1.stats.timeRescale];
AIC1 = [statsFile1.stats.AIC];

timeRescale2 = [statsFile2.stats.timeRescale];
AIC2 = [statsFile2.stats.AIC];

neurons = load(sprintf('%s/%s/Collected GAMfit/neurons.mat', modelDir, modelList(model1)));
brainAreas = {neurons.neurons.brainArea};
monkeyNames = upper({neurons.neurons.monkey});

clear statsFile1 statsFile2 neurons
figure;
[KS_handle1, QQ_handle1] = plotModelTimeRescale(timeRescale1(ismember(brainAreas, brainArea)), 'b');
[KS_handle2, QQ_handle2] = plotModelTimeRescale(timeRescale2(ismember(brainAreas, brainArea)), 'r');

legend([KS_handle1, KS_handle2], {model1, model2}); 

end

function [KS_handle, QQ_handle] = plotModelTimeRescale(timeRescale, color)
for neuronInd = 1:length(timeRescale),
    
    numSpikes = timeRescale(neuronInd).numSpikes;
    if numSpikes > 2000,
        % Downsample
        sample_ind = sort(randperm(numSpikes, 2000));
    else
        sample_ind = 1:numSpikes;
    end
    uniformCDFvalues = timeRescale(neuronInd).uniformCDFvalues(sample_ind);
    sortedKS = timeRescale(neuronInd).sortedKS(sample_ind);
    rescaledISIs = sort(timeRescale(neuronInd).rescaledISIs(sample_ind), 'ascend');
    
    subplot(2,2,1);
    KS_handle = plot(uniformCDFvalues, sortedKS - uniformCDFvalues, 'color', color); hold all;
    ylabel('Model CDF - Empirical CDF');
    xlabel('Quantiles');
    title('KS Test');
    %     hline([-ksCI ksCI], 'k--');
    hline(0, 'k-');
    box off;
    
    subplot(2,2,2);
    QQ_handle = plot(rescaledISIs, expinv(uniformCDFvalues), '-', 'color', color); hold all;
    ylabel('Expected Theorectical ISI Quantiles');
    xlabel('Observed ISI Quantiles');
    lineHandle = line([0 max(rescaledISIs)], [0 max(rescaledISIs)]);
    lineHandle.Color = 'black';
    axis([0 max(rescaledISIs) 0 max(rescaledISIs)]);
    title('Q-Q Plot');
    box off;
    
end

subplot(2,2,3);
ksStat = [timeRescale.ksStat];
h = histogram(ksStat, 'Normalization', 'probability', 'DisplayStyle', 'stairs');
alpha(0.5);
ylim([0 1]);
vline(median(ksStat), color)
hold all;
h.EdgeColor = color;
title('KS Stat');
xlabel('KS Stat');
ylabel('Probability');
box off;

end