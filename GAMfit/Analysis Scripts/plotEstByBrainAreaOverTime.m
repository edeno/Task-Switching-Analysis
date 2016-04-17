function plotEstByBrainAreaOverTime(modelName, timePeriods, varargin)
inParser = inputParser;
inParser.addRequired('modelName', @iscell);
inParser.addRequired('timePeriod', @iscell);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('colors', [0 0 0], @isnumeric);
inParser.addParameter('onlySig', false, @islogical);

inParser.parse(modelName, timePeriods, varargin{:});
params = inParser.Results;

bootEst = @(x) squeeze(quantile(nanmedian(x, 1), [0.025, 0.5, 0.975], 3));
brainAreas = {'ACC', 'dlPFC'};

for area_ind = 1:length(brainAreas),
    parEst = cell(size(timePeriods));
    parEstAbs = cell(size(timePeriods));
    h = cell(size(timePeriods));
    gam = cell(size(timePeriods));
    for time_ind = 1:length(timePeriods),
        [est, gam{time_ind}, h{time_ind}] = filterCoef(modelName{time_ind}, timePeriods{time_ind}, brainAreas{area_ind}, params);
        parEst{time_ind} = bootEst(est(:, 2:end, :));
        parEstAbs{time_ind} = bootEst(abs(est(:, 2:end, :)));
        h{time_ind} = mean(h{time_ind}, 1) * 100;
    end
    
    gam = [gam{:}];
    levelLength = arrayfun(@(x) length(x.levelNames(2:end)), gam, 'UniformOutput', false);
    levelLength = [levelLength{:}];
    [maxLevelLength, max_ind] = max(levelLength);
    levelNames = gam(max_ind).levelNames(2:end);
    covNames = gam(max_ind).covNames(2:end);
    
    timeEst = nan(maxLevelLength, 3, length(timePeriods));
    timeEstAbs = nan(maxLevelLength, 3, length(timePeriods));
    sig = nan(maxLevelLength, length(timePeriods));
    for time_ind = 1:length(timePeriods),
        level_ind = ismember(levelNames, gam(time_ind).levelNames);
        timeEst(level_ind, :, time_ind) = parEst{time_ind};
        timeEstAbs(level_ind, :, time_ind) = parEstAbs{time_ind};
        sig(level_ind, time_ind) = h{time_ind}(2:end);
    end
    
    plotTimeEst(timeEst, timeEstAbs, sig, timePeriods, levelNames, covNames);
    set(gcf, 'Name', brainAreas{area_ind});
end


end

function [parEst, gam, h] = filterCoef(modelName, timePeriods, brainArea, params)
[parEst, gam, ~, ~, ~, h] = getCoef(modelName, timePeriods, 'brainArea', brainArea, 'isSim', true, 'subject', params.subject);

numLevels = length(gam.levelNames);

bad_ind = (exp(parEst(:, 1, :)) * 1000) <  0.5; % exclude neurons with < 0.5 Hz firing rate
bad_ind = repmat(bad_ind, [1, numLevels, 1]);
parEst(bad_ind) = NaN;
if params.onlySig,
    h = repmat(h, [1 1 size(parEst, 3)]);
    parEst(~h) = NaN;
end
end

function plotTimeEst(timeEst, timeEstAbs, h, timePeriods, levelNames, covNames)

timeEstCI = exp(squeeze(timeEst(:, [1 3], :)));
timeEstMean = exp(squeeze(timeEst(:, 2, :)));

timeEstAbsCI = exp(squeeze(timeEstAbs(:, [1 3], :)));
timeEstAbsMean = exp(squeeze(timeEstAbs(:, 2, :)));

numTimePeriods = length(timePeriods);
[covID, uniqueCovNames] = grp2idx(covNames);
numCov = length(uniqueCovNames);
p = cell(numCov, 1);
maxEst = max(exp(timeEst(:))) + 0.01;
maxEstAbs = max(exp(timeEstAbs(:))) + 0.01;
maxH = max(h(:)) + 5;
figure;
%%
for cov_ind = 1:length(uniqueCovNames),
    subplot(3, numCov, cov_ind)
    p{cov_ind} = plot(1:numTimePeriods, timeEstMean(covID == cov_ind, :), '.-', 'MarkerSize', 20);
    hold all;
    l = cell(sum(covID == cov_ind), 1);
    lID = find(covID == cov_ind);
    for l_ind = 1:length(lID),
        l{l_ind} = line(repmat(1:numTimePeriods, [2 1]), squeeze(timeEstCI(lID(l_ind), :, :)));
        set(l{l_ind}, 'Color', get(p{cov_ind}(l_ind), 'Color'));
    end
    box off;
    set(gca, 'XTick', 1:numTimePeriods);
    set(gca, 'XTickLabel', '');
    t = text((0.1 + numTimePeriods) * ones(length(levelNames(covID == cov_ind)), 1), timeEstMean(covID == cov_ind, end), levelNames(covID == cov_ind));
    if length(p{cov_ind}) == 1,
        set(t, 'Color', get(p{cov_ind}, 'Color'));
    else
        set(t, {'Color'}, get(p{cov_ind}, 'Color'));
    end
    grid on;
    xlim([1 - 0.1,numTimePeriods + 0.1]);
    ylim([(1 / maxEst) maxEst]);
    hline(1, 'LineType', '-', 'Color', 'black');
    title(uniqueCovNames{cov_ind})
    if cov_ind ~= 1,
        set(gca, 'YTickLabel', []);
    else
        ylabel('Mult. Change')
    end
end
%%
for cov_ind = 1:length(uniqueCovNames),
    subplot(3, length(uniqueCovNames), numCov + cov_ind)
    p{cov_ind} = plot(1:numTimePeriods,  timeEstAbsMean(covID == cov_ind, :), '.-', 'MarkerSize', 20);
    hold all;
    l = cell(sum(covID == cov_ind), 1);
    lID = find(covID == cov_ind);
    for l_ind = 1:length(lID),
        l{l_ind} = line(repmat(1:numTimePeriods, [2 1]), squeeze(timeEstAbsCI(lID(l_ind), :, :)));
        set(l{l_ind}, 'Color', get(p{cov_ind}(l_ind), 'Color'));
    end
    box off;
    set(gca, 'XTick', 1:numTimePeriods);
    set(gca, 'XTickLabel', '');
    t = text((0.1 + numTimePeriods) * ones(length(levelNames(covID == cov_ind)), 1), timeEstAbsMean(covID == cov_ind, end), levelNames(covID == cov_ind));
    if length(p{cov_ind}) == 1,
        set(t, 'Color', get(p{cov_ind}, 'Color'));
    else
        set(t, {'Color'}, get(p{cov_ind}, 'Color'));
    end
    grid on;
    xlim([1 - 0.1, numTimePeriods + 0.1]);
    ylim([1 maxEstAbs]);
    if cov_ind ~= 1,
        set(gca, 'YTickLabel', []);
    else
        ylabel('Abs. Mult. Change')
    end
end
%%
for cov_ind = 1:length(uniqueCovNames),
    subplot(3, length(uniqueCovNames), (numCov * 2) + cov_ind)
    p{cov_ind} = plot(1:numTimePeriods,  h(covID == cov_ind, :), '.-', 'MarkerSize', 20);
    box off;
    set(gca, 'XTick', 1:numTimePeriods);
    set(gca, 'XTickLabel', strrep(timePeriods, ' ', '\newline'))
    t = text((0.1 + numTimePeriods) * ones(length(levelNames(covID == cov_ind)), 1), h(covID == cov_ind, end), levelNames(covID == cov_ind));
    if length(p{cov_ind}) == 1,
        set(t, 'Color', get(p{cov_ind}, 'Color'));
    else
        set(t, {'Color'}, get(p{cov_ind}, 'Color'));
    end
    grid on;
    xlim([1 - 0.1, numTimePeriods + 0.1]);
    ylim([0 maxH]);
    if cov_ind ~= 1,
        set(gca, 'YTickLabel', []);
    else
        ylabel('Percent Significant')
    end
    
    set(gca, 'FontSize', 8);
end

end