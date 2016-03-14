function specificModelComparison(file, predictor, comparisonModel, modelsOfInterest)
load(file);
pred_ind = ismember(predType, predictor);

% colorbrewer 7-class PuOr
colors = [
    102,194,165; ...
    117, 112, 179; ...
    ] ./ 255;
numBins = length(colors);
isCC = cellfun(@(x) ~isempty(x), strfind(neuronNames, 'cc'));
isISA = cellfun(@(x) ~isempty(x), strfind(neuronNames, 'isa'));
plotColors = nan(numNeurons, 3);
plotColors(isCC, :) = colors(ones(sum(isCC), 1), :);
plotColors(isISA, :) = colors(2*ones(sum(isISA), 1), :);

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
        binWidth = 0.05;
    case 'AUC'
        axisLim(axisLim < 0.5) = 0.5;
        binWidth = 0.01;
end
%%
f = figure;
f.Name = file;
for m_ind = 1:numModels,    
    % Scatter Plot
    subplot(2, numModels, m_ind);
    bin_ind = discretize(diffMI(m_ind, :), edges);
    bin_ind(isnan(bin_ind)) = round(size(colors, 1) / 2);
    scatter(pred(MOI_ind(m_ind), :, pred_ind), pred(comparison_ind, :, pred_ind), 40, plotColors, 'filled');
    alpha(.8);
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
%     for edge_ind = 1:(length(edges) - 1),
%         b = bar(edges(edge_ind) + (binSize / 2), 100 * nansum(bin_ind == edge_ind) / numNeurons, binSize);
%         b.FaceColor = colors(edge_ind, :);
%         hold all;
%     end
    
    histogram(diffMI(m_ind, :), 'binWidth', binWidth); hold all;
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