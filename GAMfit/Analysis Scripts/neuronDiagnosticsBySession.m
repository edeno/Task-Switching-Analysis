fR = exp(designMatrix * gam.constraints' * [neurons.par_est]) * 1000;
for neuronInd = 1:length(neurons),
    
    numSpikes = stats(neuronInd).timeRescale.numSpikes;
    if numSpikes > 2000,
        % Downsample
        sample_ind = sort(randperm(numSpikes, 2000));
    else
        sample_ind = 1:numSpikes;
    end
    uniformCDFvalues = stats(neuronInd).timeRescale.uniformCDFvalues(sample_ind);
    uniformRescaledISIs = stats(neuronInd).timeRescale.uniformRescaledISIs(sample_ind);
    normalRescaledISIs = stats(neuronInd).timeRescale.normalRescaledISIs(sample_ind);
    sortedKS = stats(neuronInd).timeRescale.sortedKS(sample_ind);
    rescaledISIs = sort(stats(neuronInd).timeRescale.rescaledISIs(sample_ind), 'ascend');
    ksCI = 1.36 / sqrt(numSpikes);
    corrCI = 1.96 / sqrt(numSpikes);
    [coef, lags] = xcorr(normalRescaledISIs(~isinf(normalRescaledISIs)), 'coeff');
    
    figure;
    subplot(2,3,1:2);
    uniqueFR = unique([gam.trial_time fR(:, neuronInd)], 'rows');
    p  = plot(uniqueFR(:, 1), uniqueFR(:, 2), '.');
    box off;
    if max(uniqueFR(:, 2)) > 20,
        maxY = max(uniqueFR(:, 2));
    else
        maxY = 20;
    end
    ylim([0 maxY]);
    xlabel('Time (ms)');
    ylabel('Firing Rate (sp / s)');
    
    subplot(2,3,3);
    plot(uniformCDFvalues, sortedKS - uniformCDFvalues); hold all;
    ylabel('Model CDF - Empirical CDF');
    xlabel('Quantiles');
    title('KS Test');
    hline([-ksCI ksCI], 'k--');
    hline(0, 'k-');
    box off;
    
    subplot(2,3,4);
    plot(uniformRescaledISIs(1:end-1), uniformRescaledISIs(2:end), '.');
    alpha(0.5);
    xlabel('k - 1'); ylabel('k');
    box off;
    title('Consecutive Intervals of Uniform ISIs');
    
    subplot(2,3,5);
    
    plot(lags, coef, '.');
    alpha(0.5);
    xlim(lags([1 end]));
    hline([-corrCI corrCI], 'k--');
    hline(0, 'k-');
    box off;
    ylabel('Correlation Coefficient');
    xlabel('Lags');
    title('Autocorrelation of Uniform ISIs');
    
    subplot(2,3,6);
    plot(rescaledISIs, expinv(uniformCDFvalues), '.')
    ylabel('Expected Theorectical ISI Quantiles');
    xlabel('Observed ISI Quantiles');
    lineHandle = line([0 max(rescaledISIs)], [0 max(rescaledISIs)]);
    lineHandle.Color = 'black';
    axis([0 max(rescaledISIs) 0 max(rescaledISIs)]);
    title('Q-Q Plot');
    box off;
    
    suptitle({sprintf('%s Neuron: %s.%d.%d', ...
        neurons(neuronInd).brainArea, ...
        neurons(neuronInd).session_name, ...
        neurons(neuronInd).wire_number, ...
        neurons(neuronInd).unit_number), ...
        sprintf('Model: %s', gamParams.regressionModel_str), ...
        sprintf('Time Period: %s', gamParams.timePeriod)});
end