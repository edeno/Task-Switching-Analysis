clear variables;
load('neurons.mat');
load('stats.mat');

brainAreas = unique({neurons.brainArea});

for brainArea_ind = 1:length(brainAreas),
    figure;
    
    for neuronInd = 1:length(stats),
        
        isBrainArea = strcmp(neurons(neuronInd).brainArea, brainAreas{brainArea_ind});
        if ~isBrainArea,
            continue;
        end
        
        numSpikes = stats(neuronInd).timeRescale.numSpikes;
        if numSpikes > 2000,
            % Downsample
            sample_ind = sort(randperm(numSpikes, 2000));
        else
            sample_ind = 1:numSpikes;
        end
        
        uniformCDFvalues = stats(neuronInd).timeRescale.uniformCDFvalues(sample_ind);
        sortedKS = stats(neuronInd).timeRescale.sortedKS(sample_ind);
        rescaledISIs = sort(stats(neuronInd).timeRescale.rescaledISIs(sample_ind), 'ascend');
        
        subplot(1,2,1);
        plot(uniformCDFvalues, sortedKS - uniformCDFvalues, 'b'); hold all;
        ylabel('Model CDF - Empirical CDF');
        xlabel('Quantiles');
        title('KS Test');
        hline(0, 'k-');
        box off;
        
        subplot(1,2,2);
        plot(rescaledISIs, expinv(uniformCDFvalues), 'b.');
        hold all;
        ylabel('Expected Theorectical ISI Quantiles');
        xlabel('Observed ISI Quantiles');
        lineHandle = line([0 max(rescaledISIs)], [0 max(rescaledISIs)]);
        lineHandle.Color = 'black';
        axis([0 1 0 1]);
        title('Q-Q Plot');
        box off;
        
    end
    
    suptitle({sprintf('Brain Area: %s', brainAreas{brainArea_ind}), ...
        sprintf('Model: %s', gamParams.regressionModel_str), ...
        sprintf('Time Period: %s', gamParams.timePeriod)});
    
end