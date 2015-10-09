close all;
fR = exp(designMatrix * gam.constraints' * [neurons.par_est]) * 1000;
for neuronInd = 1:length(neurons),
    
    uniformCDFvalues = stats(neuronInd).timeRescale.uniformCDFvalues;
    uniformRescaledISIs = stats(neuronInd).timeRescale.uniformRescaledISIs;
    normalRescaledISIs = stats(neuronInd).timeRescale.normalRescaledISIs;
    rescaledISIs = sort(stats(neuronInd).timeRescale.rescaledISIs, 'ascend');
    numSpikes = stats(neuronInd).timeRescale.numSpikes;
    ksCI = 1.36 / sqrt(numSpikes);
    corrCI = 1.96 / sqrt(numSpikes);
    [coef, lags] = xcorr(normalRescaledISIs(~isinf(normalRescaledISIs)), 'coeff');
        
    figure;
    subplot(2,3,1:2);
    plot(gam.trial_time, fR(:, neuronInd), '.');
    box off;
    xlabel('Time (ms)');
    ylabel('Firing Rate (sp / s)');
    
    subplot(2,3,3);
    
    
    plot(uniformCDFvalues, stats(neuronInd).timeRescale.sortedKS - uniformCDFvalues); hold all;
    ylabel('Model CDF - Empirical CDF');
    xlabel('Quantiles');
    title('KS Test');
    hline([-ksCI ksCI], 'k--');
    hline(0, 'k-');
    box off;
    
    subplot(2,3,4);
    plot(uniformRescaledISIs(1:end-1), uniformRescaledISIs(2:end), '.');
    xlabel('k - 1'); ylabel('k');
    box off;
    title('Consecutive Intervals of Uniform ISIs');
    
    subplot(2,3,5);
    
    plot(lags, coef, '.');
    hline([-corrCI corrCI], 'k--');
    hline(0, 'k-');
    box off;
    ylabel('Correlation Coefficient');
    xlabel('Lags');
    title('Autocorrelation of Uniform ISIs');
    
    subplot(2,3,6);
    plot(rescaledISIs, expinv(uniformCDFvalues), '.')
    ylabel('Expected Theorectical ISI Quantiles');
    xlabel('Observed ISIs');
    lineHandle = line([0 max(rescaledISIs)], [0 max(rescaledISIs)]);
    lineHandle.Color = 'black';
    axis([0 max(rescaledISIs) 0 max(rescaledISIs)]);
    title('Q-Q Plot');
    box off;
    
    suptitle({sprintf('%s Neuron: %s.%d.%d', ...
        neurons(neuronInd).brainArea, ...
        neurons(neuronInd).session_name, ...
        neurons(neuronInd).wire_number, ...
        neurons(neuronInd).unit_number), gam.model_str, gamParams.timePeriod})
end