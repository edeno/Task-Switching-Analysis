function specificModelComparison(file, predictor, comparisonModel, modelsOfInterest)
load(file);
pred_ind = ismember(predType, predictor);

% colorbrewer 7-class PuOr
colors = [165,0,38; ...
    215,48,39; ...
    244,109,67; ...
    253,174,97; ...
    254,224,139; ...
    186,186,186; ...
    217,239,139; ...
    166,217,106; ...
    102,189,99; ...
    26,152,80; ...
    0,104,55; ...
    ] ./ 255;
numBins = length(colors);

comparison_ind = find(ismember(models, comparisonModel));
MOI_ind = find(ismember(models, modelsOfInterest));
numModels = length(modelsOfInterest);
%%
diffMI = nan(numModels, numNeurons);
meanDiffMI = nan(numModels, 1);
for m_ind = 1:numModels,
    diffMI(m_ind, :) = pred(comparison_ind, :, pred_ind) - pred(MOI_ind(m_ind), :, pred_ind);
    meanDiffMI(m_ind) = nanmean(diffMI(m_ind, :));
end

edges = linspace(-1*max(abs(quantile(diffMI(:), [0 1]))), max(abs(quantile(diffMI(:), [0 1]))), numBins + 1);
binSize = edges(2) - edges(1);
axisLim = quantile(reshape(pred([comparison_ind, MOI_ind], :, pred_ind), [], 1), [0 1]);

switch(predictor)
    case 'mutualInformation'
        axisLim(axisLim < 0) = 0;
    case 'AUC'
        axisLim(axisLim < 0.5) = 0.5;
end
%%
f = figure;
f.Name = file;
for m_ind = 1:numModels,    
    % Scatter Plot
    subplot(2, numModels, m_ind);
    bin_ind = discretize(diffMI(m_ind, :), edges);
    scatter(pred(MOI_ind(m_ind), :, pred_ind), pred(comparison_ind, :, pred_ind), 40, colors(bin_ind, :), 'filled');
    ylim(axisLim);
    xlim(axisLim);
    l = line(axisLim, axisLim);
    l.Color = 'black';
    if (m_ind == 1)
        y = ylabel(strsplit(models{comparison_ind}, ' + '));
        y.FontSize = 8;
        y.Rotation = 0;
        y.HorizontalAlignment = 'right';
        y.VerticalAlignment = 'middle';
    end
    
    % Histogram of Differences
    subplot(2, numModels, m_ind + numModels);
    for edge_ind = 1:(length(edges) - 1),
        b = bar(edges(edge_ind) + (binSize / 2), 100 * sum(bin_ind == edge_ind) / numNeurons, binSize);
        b.FaceColor = colors(edge_ind, :);
        hold all;
    end
    
    vline(0, 'Color', 'black', 'LineType', '-');
    vline(meanDiffMI(m_ind));
    xlim(quantile(edges, [0 1]));
    box off;
    x = xlabel(strsplit(models{MOI_ind(m_ind)}, ' + '));
    x.FontSize = 8;
    
    if (m_ind == 1)
        y = ylabel(strsplit(models{comparison_ind}, ' + '));
        y.FontSize = 8;
        y.Rotation = 0;
        y.HorizontalAlignment = 'right';
        y.VerticalAlignment = 'middle';
    end
end

end