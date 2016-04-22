clear variables;
timePeriod = 'Rule Stimulus';
models = {...
    'Rule', ...
    'Previous Error History', ...
    'Rule Repetition', ...
    'Rule + Previous Error History', ...
    'Rule + Rule Repetition', ...
    'Previous Error History + Rule Repetition', ...
    'Rule + Previous Error History + Rule Repetition', ...
    'Rule * Previous Error History + Rule Repetition', ...
    'Previous Error History + Rule * Rule Repetition', ...
    'Rule * Previous Error History + Rule * Rule Repetition', ...
    };

for model_ind = 1:length(models),
    [p, gam, neuronNames, neuronBrainAreas] = getPred(models{model_ind}, timePeriod, 'brainArea', 'ACC');
    pred(:, model_ind) = mean(p, 2);
end

[best, best_ind] = max(pred, [], 2);

t  = tabulate(best_ind);
percentBest = zeros(length(models), 1);
percentBest(t(:, 1)) = t(:, 3);

covComb = cellfun(@(x) strsplit(x, ' + '), models, 'UniformOutput', false);
uniqueCovComb = unique([covComb{:}], 'stable');

factorImportance = nan(size(uniqueCovComb));
for uniqueCov_ind = 1:length(uniqueCovComb),
    factorImportance(uniqueCov_ind) = mean(cellfun(@(x) ismember(uniqueCovComb(uniqueCov_ind), x), covComb(best_ind))) * 100;
end

%%
figure;
b = bar(factorImportance);
b.Horizontal = 'on';
set(gca, 'YTick', 1:length(uniqueCovComb));
set(gca, 'YTickLabel',uniqueCovComb);
set(gca, 'TickLength', [0 0]);
title('Factor Importance to Prediction');
%%
colors = [27,158,119; ...
    217,95,2; ...
    117,112,179; ...
    231,41,138; ...
    102,166,30; ...
    230,171,2; ...
    166,118,29; ...
    102,102,102] ./ 255;
barWidth = 0.5;
f = figure;
ha = tight_subplot(2, 1, [.01 .01], [.1 .01],[.2 .01]);
axes(ha(1));
bar(1:length(percentBest), percentBest);
set(gca, 'XTickLabel', []);
set(gca, 'XTick', 1:length(percentBest));
set(gca, 'TickLength', [0 0]);
box off;
xlim([1 - barWidth, length(percentBest) + barWidth]);
ylabel('Percent Significant');

axes(ha(2));
markerWidth = 30; % Calculate Marker width in points

ylim([1 - barWidth, length(uniqueCovComb) + barWidth]);
for model_ind = 1:length(models),
    covID = find(ismember(uniqueCovComb, covComb{model_ind}));
    plot(model_ind * ones(size(covID)), covID, 'k.-', 'MarkerSize', markerWidth, 'LineWidth', .1);
    hold all;
    p = plot(model_ind, covID, '.', 'MarkerSize', markerWidth);
    set(p, {'Color'}, num2cell(colors(covID, :), 2));
end
set(gca, 'XTick', 1:length(percentBest))
set(gca, 'XTickLabel', []);
set(gca, 'YTick', 1:length(uniqueCovComb));
set(gca, 'YTickLabel', uniqueCovComb);
set(gca, 'TickLength', [0 0])
xlim([1 - barWidth, length(percentBest) + barWidth]);
box off;
grid on;