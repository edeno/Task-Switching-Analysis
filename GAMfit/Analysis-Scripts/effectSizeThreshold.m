clear variables;
brainArea = 'dlPFC';
params.subject = '*';
params.numSim = 1E4;
modelName = 'Rule + Previous Error History + Rule Repetition';
timePeriods = 'Rule Stimulus';

[parEst, gam] = getCoef(modelName, timePeriods, 'brainArea', brainArea, 'isSim', true, 'subject', params.subject, 'numSim', params.numSim);

bad_ind = abs(parEst) > 10;
bad_ind(:, 1, :) = false;

parEst(bad_ind) = NaN;

parEst = 100 * (exp(parEst(:, 2:end, :)) - 1);

thresholds = -100:1:100;
thresholds(thresholds == 0) = [];
percentGreaterThanThresh = nan(length(thresholds), size(parEst, 2), 3);

for thresh_ind = 1:length(thresholds),
    if thresholds(thresh_ind) > 0,
        percentGreaterThanThresh(thresh_ind, :, :) = quantile(mean(double(parEst > thresholds(thresh_ind)), 1), [0.025, 0.5, 0.975], 3) * 100;
    else
        percentGreaterThanThresh(thresh_ind, :, :) = quantile(mean(double(parEst < thresholds(thresh_ind)), 1), [0.025, 0.5, 0.975], 3) * 100;
    end
end

covNames = gam.covNames(2:end);
load('paramSet.mat', 'colorInfo');
levelNames = gam.levelNames(2:end);
numLevels = length(levelNames);
%%
sub = numSubplots(numLevels);
figure;
for ind = 1:numLevels,
    subplot(sub(1), sub(2), ind)
    data = squeeze(percentGreaterThanThresh(:, ind, :));
    plot(thresholds, data(:, 2),  '.', 'Color', colorInfo(levelNames{ind}), 'MarkerSize', 10);
    hold all;
    plot(thresholds, data(:, 2),  '-', 'Color', colorInfo(levelNames{ind}), 'LineWidth', 2);
    l = line(repmat(thresholds, [2, 1]), data(:, [1 3])');
    set(l, 'Color', colorInfo(levelNames{ind}));
    set(l, 'LineWidth', 2);
    title(levelNames{ind});
    ylim([0 100]);
    box off;
    xlabel('Percent Change in Firing Rate Threshold');
    ylabel('Percentage of Neurons > Threshold');
end


