function CompareModelPredictions(filename)
load(filename);
pred = pred(~ismember(models, 'Constant'), :, :);
models = models(~ismember(models, 'Constant'));
numModels = length(models);
predType = predType(1:2);
numPred = length(predType);

%% Parallel Histograms
for pred_ind = 1:length(predType),
    f = figure;
    f.Name = [brainArea, ' - ', predType{pred_ind}, ' - Parallel Histograms'];
    if ~strcmp(predType{pred_ind}, 'Dev'),
        [~, sort_ind] = sort(nanmean(squeeze(pred(:, :, pred_ind)), 2), 'descend');
    else
        [~, sort_ind] = sort(nanmean(squeeze(pred(:, :, pred_ind)), 2), 'ascend');
    end
    p = squeeze(pred(:, :, pred_ind));
    p = p(:);
    extent = quantile(p, [0.01 0.99]);
    for model_ind = 1:numModels,
        subplot(numModels, 1, model_ind);
        histogram(squeeze(pred(sort_ind(model_ind), :, pred_ind)), 100);
        box off;
        vline(nanmean(squeeze(pred(sort_ind(model_ind), :, pred_ind))));
        xlim([extent])
        xAxis = get(gca, 'xAxis');
        yAxis = get(gca, 'yAxis');
        y = ylabel(models{sort_ind(model_ind)});
        y.FontSize = 8;
        y.Rotation = 0;
        y.HorizontalAlignment = 'right';
    end
end

%% Scatterplot Matrix
for pred_ind = 1:length(predType),
    f = figure;
    f.Name = [brainArea, ' - ', predType{pred_ind}, '- Scatterplot Matrix'];
    p = squeeze(pred(:, :, pred_ind));
    p = p(:);
    extent = quantile(p, [0.01 0.99]);
    count = 1;
    ha = tight_subplot(numModels, numModels, [0 0], [0.1 0.01], 0.1);
    for model1_ind = 1:numModels,
        for model2_ind = 1:numModels,
            axes(ha(count));
            
            color_ind_pos = squeeze(pred(model1_ind, :, pred_ind)) - squeeze(pred(model2_ind, :, pred_ind)) > 0;
            color_ind_neg = squeeze(pred(model1_ind, :, pred_ind)) - squeeze(pred(model2_ind, :, pred_ind)) < 0;
            color = cell(size(color_ind_pos));
            [color{color_ind_pos}] = deal([0 1 0]);
            [color{color_ind_neg}] = deal([1 0 0]);
            [color{~color_ind_pos & ~color_ind_neg}] = deal([0 0 0]);
            color = cat(1, color{:});
            
            scatter(squeeze(pred(model2_ind, :, pred_ind)), squeeze(pred(model1_ind, :, pred_ind)), 10, color)
            xlim(extent);
            ylim(extent);
            l = line(extent, extent);
            l.Color = 'black';
            set(gca, 'TickLength', [0 0]);
            if model2_ind == 1
                y = ylabel(strsplit(models{model1_ind}, ' + '));
                y.FontSize = 8;
                y.Rotation = 0;
                y.HorizontalAlignment = 'right';
                y.VerticalAlignment = 'middle';
            end
            if model1_ind == numModels;
                x = xlabel(strsplit(models{model2_ind}, ' + '));
                x.FontSize = 8;
            end
            if (count ~= (numModels * numModels))
                set(gca,'XTickLabel','')
                set(gca,'YTickLabel','')
            else
                set(gca, 'FontSize', 8);
                set(gca, 'YAxisLocation', 'right');
            end
            count = count + 1;
        end
    end
end

%% Hex Scatter
for pred_ind = 1:length(predType),
    f = figure;
    f.Name = [brainArea, ' - ', predType{pred_ind}, ' - Hex Scatter'];
    p = squeeze(pred(:, :, pred_ind));
    p = p(:);
    extent = quantile(p, [0.01 0.99]);
    count = 1;
    ha = tight_subplot(numModels, numModels, [0 0], [0.05 0.1], 0.1);
    for model1_ind = 1:numModels,
        for model2_ind = 1:numModels,
            axes(ha(count));
            
            xdata = squeeze(pred(model2_ind, :, pred_ind))';
            ydata = squeeze(pred(model1_ind, :, pred_ind))';
            
            outOfBounds = xdata < extent(1) | xdata > extent(2) | ydata < extent(1) | ydata > extent(2);
            xdata(outOfBounds) = [];
            ydata(outOfBounds) = [];
            
            if model1_ind ~= model2_ind,
                hexscatter(xdata, ydata, 'xlim', extent, 'ylim', extent, 'res', 10);
                xlim(extent);
                ylim(extent);
                l = line(extent, extent);
                l.Color = 'black';
            else
                histogram(xdata);
            end
            set(gca, 'TickLength', [0 0]);
            if model2_ind == 1
                y = ylabel(strsplit(models{model1_ind}, ' + '));
                y.FontSize = 8;
                y.Rotation = 0;
                y.HorizontalAlignment = 'right';
                y.VerticalAlignment = 'middle';
            end
            if model1_ind == numModels;
                x = xlabel(strsplit(models{model2_ind}, ' + '));
                x.FontSize = 8;
            end
            if (count ~= numModels)
                set(gca,'XTickLabel','')
                set(gca,'YTickLabel','')
            else
                set(gca, 'FontSize', 8);
                set(gca, 'YAxisLocation', 'right');
                
            end
            box on;
            count = count + 1;
        end
    end
end

% Need to add legend
%% Parallel Coordinates
for pred_ind = 1:numPred,
    f = figure;
    f.Name = [brainArea, ' - ', predType{pred_ind}, ' - Parallel Coordinates'];
    plot(pred(:, :, pred_ind), 1:numModels)
    set(gca, 'YTick', 1:numModels);
    set(gca, 'YTickLabel', models);
    set(gca, 'XAxisLocation', 'top');
    box off;
end

% Excluding outliers
for pred_ind = 1:numPred,
    f = figure;
    f.Name = [brainArea, ' - ', predType{pred_ind}];
    p = squeeze(pred(:, :, pred_ind));
    p = p(:);
    extent = quantile(p, [0.01 0.99]);
    plot(pred(:, :, pred_ind), 1:numModels)
    xlim(extent);
    set(gca, 'YTick', 1:numModels);
    set(gca, 'YTickLabel', models);
    set(gca, 'XAxisLocation', 'top');
    box off;
end


%% Best model
for pred_ind = 1:numPred,
    [~, max_ind] = max(pred(:,:, pred_ind), [], 1);
    f = figure;
    f.Name = [brainArea, ' - ', predType{pred_ind}, ' - Best Model'];
    h = histogram(max_ind);
    h.Orientation = 'horizontal';
    h.Normalization = 'pdf';
    set(gca, 'YTick', 1:numModels);
    set(gca, 'YTickLabel', models);
    box off;
    title('Best Model')
end
end
