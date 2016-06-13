clear variables;
brainArea = 'ACC';
params.subject = '*';
params.numSim = 1E4;
modelName = 'Rule + Previous Error History + Rule Repetition';
timePeriods = 'Rule Stimulus';

[parEst, gam] = getCoef(modelName, timePeriods, 'brainArea', brainArea, 'isSim', true, 'subject', params.subject, 'numSim', params.numSim);

bad_ind = abs(parEst) > 10;
bad_ind(:, 1, :) = false;

parEst(bad_ind) = NaN;

parEst = 100 * (exp(parEst(:, 2:end, :)) - 1);

thresholds = 0:1:100;
percentGreaterThanThresh = nan(length(thresholds), size(parEst, 2), 3);

for thresh_ind = 1:length(thresholds),
    percentGreaterThanThresh(thresh_ind, :, :) = quantile(mean(parEst >= thresholds(thresh_ind), 1), [0.025, 0.5, 0.975], 3) * 100;
end

covNames = gam.covNames(2:end);
load('paramSet.mat', 'colorInfo');
levelNames = gam.levelNames(2:end);
%%
curCov = 'Rule Repetition';
ind = find(ismember(covNames, curCov));

figure;
for level_ind = ind(end:-1:1),
    data = squeeze(percentGreaterThanThresh(:, level_ind, :));
    plot(thresholds, data(:, 2),  '.', 'Color', colorInfo(levelNames{level_ind}), 'MarkerSize', 30);
    hold all;
    plot(thresholds, data(:, 2),  '-', 'Color', colorInfo(levelNames{level_ind}), 'LineWidth', 3);
    l = line(repmat(thresholds, [2, 1]), data(:, [1 3])');
    set(l, 'Color', colorInfo(levelNames{level_ind}));
    set(l, 'LineWidth', 3);
end
box off;
ylim([0 100]);
title(curCov);
xlabel('Percent Change in Firing Rate Threshold');
ylabel('Percentage of Neurons > Threshold');

%%
curCov = 'Previous Error History';
ind = find(ismember(covNames, curCov));

figure;
for level_ind = ind(end:-1:1),
    data = squeeze(percentGreaterThanThresh(:, level_ind, :));
    plot(thresholds, data(:, 2),  '.', 'Color', colorInfo(levelNames{level_ind}), 'MarkerSize', 30);
    hold all;
    plot(thresholds, data(:, 2),  '-', 'Color', colorInfo(levelNames{level_ind}), 'LineWidth', 3);
    l = line(repmat(thresholds, [2, 1]), data(:, [1 3])');
    set(l, 'Color', colorInfo(levelNames{level_ind}));
    set(l, 'LineWidth', 3);
end
box off;
ylim([0 100]);
title(curCov);
xlabel('Percent Change in Firing Rate Threshold');
ylabel('Percentage of Neurons > Threshold');