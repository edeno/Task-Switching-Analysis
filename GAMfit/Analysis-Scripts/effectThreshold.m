function [comparePosNeg, compareAreas, bootPercentGreaterThanThresh, levelNames, covNames, brainAreas, params] = effectThreshold(modelName, timePeriod, varargin)
inParser = inputParser;
inParser.addRequired('modelName', @ischar);
inParser.addRequired('timePeriod', @ischar);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('numSim', 1E4, @isnumeric);
inParser.addParameter('thresholds', 5:100, @(x) isnumeric(x) & all(x > 0));

inParser.parse(modelName, timePeriod, varargin{:});
params = inParser.Results;
params.thresholds = [-1 * (params.thresholds(end:-1:1)), params.thresholds]; % symmetric

brainAreas = {'ACC', 'dlPFC'};

numBrainAreas = length(brainAreas);
numThresh = length(params.thresholds);
parEst = cell(numBrainAreas, 1);
percentGreaterThanThresh = cell(numBrainAreas, numThresh);

for area_ind = 1:numBrainAreas,
    [est, gam] = filterCoef(modelName, timePeriod, brainAreas{area_ind}, params);
    parEst{area_ind} = 100 * (exp((est(:, 2:end, :))) - 1);
    for thresh_ind = 1:numThresh,
        if params.thresholds(thresh_ind) > 0
            percentGreaterThanThresh{area_ind, thresh_ind} = squeeze(nanmean(parEst{area_ind} > params.thresholds(thresh_ind)) * 100);
        else
            percentGreaterThanThresh{area_ind, thresh_ind} = squeeze(nanmean(parEst{area_ind} < params.thresholds(thresh_ind)) * 100);
        end
    end
end

covNames = gam.covNames(2:end);
levelNames = gam.levelNames(2:end);
boot = @(x) quantile(x, [0.025, 0.5, 0.975], 2);
% Within Brain Area Comparisons (compare positive thresholds to
% corresponding negative thresholds)
comparePosNeg_ind = [1:(numThresh/2); numThresh:-1:(numThresh/2)+1];
comparePosNeg_ind = comparePosNeg_ind(:, (numThresh/2):-1:1);
comparePosNeg = nan(size(comparePosNeg_ind, 2), length(levelNames), 3, numBrainAreas);
for area_ind = 1:numBrainAreas,
    for posNeg_ind = 1:size(comparePosNeg_ind, 2),
        stat = percentGreaterThanThresh{1, comparePosNeg_ind(2, posNeg_ind)} - percentGreaterThanThresh{1, comparePosNeg_ind(1, posNeg_ind)};
        comparePosNeg(posNeg_ind, :, :, area_ind) = boot(stat);
    end
end

compareAreas = nan(numThresh, length(levelNames), 3);
% Between Area Comparisons
for thresh_ind = 1:numThresh,
    stat = percentGreaterThanThresh{1, thresh_ind} - percentGreaterThanThresh{2, thresh_ind};
    compareAreas(thresh_ind, :, :) = boot(stat);
end

% Bootstrapped Percentages
bootPercentGreaterThanThresh = cellfun(@(x) boot(x), percentGreaterThanThresh, 'UniformOutput', false);
end

function [parEst, gam] = filterCoef(modelName, timePeriods, brainArea, params)
[parEst, gam] = getCoef(modelName, timePeriods, 'brainArea', brainArea, 'isSim', true, 'subject', params.subject, 'numSim', params.numSim);

bad_ind = abs(parEst) > 10;
bad_ind(:, 1, :) = false;

parEst(bad_ind) = NaN;
end