function plotPredComb(models, timePeriod, varargin)
inParser = inputParser;
inParser.addRequired('models', @iscell);
inParser.addRequired('timePeriod', @ischar);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('brainArea', '*', @ischar);
inParser.addParameter('predType', 'AUC', @ischar);

inParser.parse(models, timePeriod, varargin{:});
params = inParser.Results;

for model_ind = 1:length(models),
    [p, ~, ~, ~] = getPred(models{model_ind}, timePeriod, ...
        'brainArea', params.brainArea, ...
        'predType', params.predType, ...
        'subject', params.subject);
    pred(:, :, model_ind + 1) = p;
end

models = ['No Effect', models];
numModels = length(models);

if strcmp(params.predType, 'AUC'),
    pred(:, :, 1) = 0.5;
else
    pred(:, :, 1) = 0;
end

[~, best_ind] = max(pred, [], 3);

numFolds = size(pred, 2);
percentBest = zeros(numModels, numFolds);
for fold_ind = 1:numFolds,
    t = tabulate(best_ind(:, fold_ind));
    percentBest(t(:, 1), fold_ind) = t(:, 3);
end

covComb = cellfun(@(x) modelFormulaParse(x), models, 'UniformOutput', false);
covComb = cellfun(@(x) x.terms, covComb, 'UniformOutput', false);
uniqueCovComb = unique(cat(1, covComb{:}), 'stable');

factorImportance = nan(length(uniqueCovComb), numFolds);
for fold_ind = 1:numFolds,
    for uniqueCov_ind = 1:length(uniqueCovComb),
        factorImportance(uniqueCov_ind, fold_ind) = mean(cellfun(@(x) ismember(uniqueCovComb(uniqueCov_ind), x), covComb(best_ind(:, fold_ind)))) * 100;
    end
end

ste = @(x, n) bsxfun(@plus, mean(x, 2), (std(x, [], 2) / sqrt(n)) * [-1, 1]);
%% Factor Importance
f = figure;
plot(mean(factorImportance, 2), 1:length(uniqueCovComb), '.', 'MarkerSize', 20, 'Color', 'Black');
hold all;
factorImportanceSTE = ste(factorImportance, numFolds);
l = line(factorImportanceSTE', repmat(1:length(uniqueCovComb), [2, 1]));
set(l, {'Color'}, {'Black'});
set(gca, 'YTick', 1:length(uniqueCovComb));
set(gca, 'YTickLabel',uniqueCovComb);
set(gca, 'TickLength', [0 0]);
title('Factor Importance to Prediction');
xlabel('Percentage of Best Models Containing Factor')
f.Name = sprintf('%s - %s - %s', params.brainArea, timePeriod, params.predType);
%% Best Model
f = figure;
colors = [27,158,119; ...
    217,95,2; ...
    117,112,179; ...
    231,41,138; ...
    102,166,30; ...
    230,171,2; ...
    166,118,29; ...
    102,102,102] ./ 255;
barWidth = 0.5;
ha = tight_subplot(2, 1, [.01 .01], [.1 .01],[.2 .01]);
axes(ha(1));
plot(1:numModels, mean(percentBest, 2), '.', 'MarkerSize', 20, 'Color', 'Black');
l = line(repmat(1:numModels, [2, 1]), ste(percentBest, numFolds)');
set(l, {'Color'}, {'Black'});
grid on;
set(gca, 'XTickLabel', []);
set(gca, 'XTick', 1:numModels);
set(gca, 'TickLength', [0 0]);
box off;
xlim([1 - barWidth, numModels + barWidth]);
ylabel('Percent Best Model');

axes(ha(2));
markerWidth = 30; % Calculate Marker width in points

ylim([1 - barWidth, length(uniqueCovComb) + barWidth]);
for model_ind = 1:numModels,
    covID = find(ismember(uniqueCovComb, covComb{model_ind}));
    plot(model_ind * ones(size(covID)), covID, 'k.-', 'MarkerSize', markerWidth, 'LineWidth', .1);
    hold all;
    p = plot(model_ind, covID, '.', 'MarkerSize', markerWidth);
    set(p, {'Color'}, num2cell(colors(covID, :), 2));
end
set(gca, 'XTick', 1:numModels)
set(gca, 'XTickLabel', []);
set(gca, 'YTick', 1:length(uniqueCovComb));
set(gca, 'YTickLabel', uniqueCovComb);
set(gca, 'TickLength', [0 0])
xlim([1 - barWidth, numModels + barWidth]);
box off;
grid on;

f.Name = sprintf('%s - %s - %s', params.brainArea, timePeriod, params.predType);
%% Average Predictability
f = figure;

colors = [27,158,119; ...
    217,95,2; ...
    117,112,179; ...
    231,41,138; ...
    102,166,30; ...
    230,171,2; ...
    166,118,29; ...
    102,102,102] ./ 255;
barWidth = 0.5;
ha = tight_subplot(2, 1, [.01 .01], [.1 .01],[.2 .01]);
axes(ha(1));
plot(1:numModels-1, squeeze(mean(nanmean(pred(:, :, 2:end), 1), 2)), '.', 'MarkerSize', 20, 'Color', 'Black');
l = line(repmat(1:(numModels - 1), [2, 1]), ste(squeeze(nanmean(pred(:, :, 2:end), 1))', numFolds)');
set(l, {'Color'}, {'Black'});
grid on;
set(gca, 'XTickLabel', []);
set(gca, 'XTick', 1:(numModels - 1));
set(gca, 'TickLength', [0 0]);
box off;
xlim([1 - barWidth, numModels - 1 + barWidth]);
ylabel(params.predType);

axes(ha(2));
markerWidth = 30; % Calculate Marker width in points

ylim([1 - barWidth, length(uniqueCovComb) + barWidth]);
for model_ind = 2:numModels,
    covID = find(ismember(uniqueCovComb, covComb{model_ind}));
    plot(model_ind - 1 * ones(size(covID)), covID, 'k.-', 'MarkerSize', markerWidth, 'LineWidth', .1);
    hold all;
    p = plot(model_ind - 1, covID, '.', 'MarkerSize', markerWidth);
    set(p, {'Color'}, num2cell(colors(covID, :), 2));
end
set(gca, 'XTick', 1:(numModels - 1))
set(gca, 'XTickLabel', []);
set(gca, 'YTick', 1:length(uniqueCovComb));
set(gca, 'YTickLabel', uniqueCovComb);
set(gca, 'TickLength', [0 0])
xlim([1 - barWidth, numModels - 1 + barWidth]);
box off;
grid on;

f.Name = sprintf('%s - %s - %s', params.brainArea, timePeriod, params.predType);
end