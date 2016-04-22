function plotCompareDemandByBrainAreas(modelName, timePeriods, factorsOfInterest, varargin)
inParser = inputParser;
inParser.addRequired('modelName', @iscell);
inParser.addRequired('timePeriods', @iscell);
inParser.addRequired('factorsOfInterest', @iscell);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('colors', [0 0 0], @isnumeric);
inParser.addParameter('onlySig', false, @islogical);
inParser.addParameter('isAbs', false, @islogical);

inParser.parse(modelName, timePeriods, factorsOfInterest, varargin{:});
params = inParser.Results;

bootEst = @(x) squeeze(quantile(nanmean(x, 1), [0.025, 0.5, 0.975], 3));
brainAreas = {'ACC', 'dlPFC'};

numTimePeriods = length(timePeriods);
numBrainAreas = length(brainAreas);
numFactors = length(factorsOfInterest);

colorOrder = [ ...
    37,52,148; ...
    44,127,184; ...
    65,182,196; ...
    127,205,187; ...
    199,233,180; ...
    ] ./ 255;
colorOrder = num2cell(colorOrder, 2);

figure;
set(groot, 'DefaultAxesFontName', 'Arial')
s1 = cell(numBrainAreas * numFactors, 1);
s2 = cell(numBrainAreas * numFactors, 1);

for area_ind = 1:numBrainAreas,
    parEst = cell(size(timePeriods));
    parEstAbs = cell(size(timePeriods));
    h = cell(size(timePeriods));
    gam = cell(size(timePeriods));
    for time_ind = 1:numTimePeriods,
        [est, gam{time_ind}, h{time_ind}] = filterCoef(modelName{time_ind}, timePeriods{time_ind}, brainAreas{area_ind}, params);
        if params.isAbs,
            est(:, 2:end, :) = abs(est(:, 2:end, :));
        end
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
    
    timeEst = nan(maxLevelLength, 3, numTimePeriods);
    timeEstAbs = nan(maxLevelLength, 3, numTimePeriods);
    sig = nan(maxLevelLength, numTimePeriods);
    for time_ind = 1:numTimePeriods,
        level_ind = ismember(levelNames, gam(time_ind).levelNames);
        timeEst(level_ind, :, time_ind) = parEst{time_ind};
        timeEstAbs(level_ind, :, time_ind) = parEstAbs{time_ind};
        sig(level_ind, time_ind) = h{time_ind}(2:end);
    end
    
    for demand_ind = 1:numFactors,
        cov_ind = ismember(covNames, factorsOfInterest{demand_ind});
        %% Effect Size
        s1{((2 * demand_ind) - 1) + (area_ind - 1)} = subplot(2, numBrainAreas * numFactors, ((2 * demand_ind) - 1) + (area_ind - 1));
        plotEffectSize();
        
        %% Percent Significant
        s2{((2 * demand_ind) - 1) + (area_ind - 1)} = subplot(2, numBrainAreas * numFactors, ((2 * demand_ind) - 1) + (area_ind - 1) + (numBrainAreas * numFactors));
        plotPercentSig();
    end
    
    maxEst(area_ind) = max(reshape(abs(timeEst(ismember(covNames, factorsOfInterest), :, :)), 1, []));
    maxSig(area_ind) = max(reshape(sig(ismember(covNames, factorsOfInterest), :), 1, []));
end

%%
s1 = [s1{:}];

if round(exp(max(maxEst)), 1) - exp(max(maxEst)) < 0,
    mEst = round(exp(max(maxEst)), 1) + 0.05;
else
    mEst = round(exp(max(maxEst)), 1);
end

if params.isAbs,
    set(s1, 'YLim', [0, log(mEst)]);
    set(s1, 'YTick', log(1:0.05:mEst));
    set(s1, 'YTickLabel', ((1:0.05:mEst) - 1) * 100);
else
    set(s1, 'YLim', [log((1 - mEst) + 1), log(mEst)]);
    set(s1, 'YTick', log(((1 - mEst) + 1):0.05:mEst));
    set(s1, 'YTickLabel', ((((1 - mEst) + 1):0.05:mEst) - 1) * 100);
end

%%
s2 = [s2{:}];

if round(max(maxSig), -1) - max(maxSig) < 0,
    mSig = round(max(maxSig) + 5, -1);
else
    mSig = round(max(maxSig), -1);
end
set(s2, 'YLim', [0, mSig]);
set(s2, 'YTick', [0:5:mSig]);

%%
    function [parEst, gam, p] = filterCoef(modelName, timePeriods, brainArea, params)
        [parEst, gam, ~, ~, p, h] = getCoef(modelName, timePeriods, 'brainArea', brainArea, 'isSim', true, 'subject', params.subject, 'numSim', 1E4);
        
        bad_ind = abs(parEst) > 10;
        bad_ind(:, 1, :) = false;
        
        parEst(bad_ind) = NaN;
        if params.onlySig,
            h = repmat(h, [1 1 size(parEst, 3)]);
            parEst(~h) = NaN;
        end
    end
%%
    function plotEffectSize()
        plotHandle = plot(1:numTimePeriods, squeeze(timeEst(cov_ind, 2, :)), '.-', 'MarkerSize', 20, 'LineWidth', 2);
        set(plotHandle, {'Color'}, colorOrder(1:sum(cov_ind)));
        hold all;
        l = cell(sum(cov_ind), 1);
        lID = find(cov_ind);
        
        for l_ind = 1:length(lID),
            l{l_ind} = line(repmat(1:numTimePeriods, [2 1]), squeeze(timeEst(lID(l_ind), [1 3], :)));
            set(l{l_ind}, 'Color', colorOrder{l_ind, :});
        end
        box off;
        grid on;
        t = text((0.1 + numTimePeriods) * ones(length(levelNames(cov_ind)), 1), timeEst(cov_ind, 2, end), levelNames(cov_ind));
        if length(plotHandle) == 1,
            set(t, 'Color', get(plotHandle, 'Color'));
        else
            set(t, {'Color'}, get(plotHandle, 'Color'));
        end
        
        title([brainAreas(area_ind), factorsOfInterest(demand_ind)])
        if params.isAbs,
            ylim(log([1 1.25]))
            set(gca, 'YTick', log(1:.05:1.25));
            set(gca, 'YTickLabel', 100 * ([1:.05:1.25] - 1));
        else
            ylim(log([0.85 1.15]))
            set(gca, 'YTick', log(0.85:.05:1.15));
            set(gca, 'YTickLabel', 100 * ([0.85:.05:1.15] - 1));
        end
        set(gca, 'TickLength', [0, 0]);
        set(gca, 'XTick', 1:numTimePeriods);
        set(gca, 'XTickLabel', strrep(timePeriods, ' ', '\newline'))
        xlim([1 - 0.5, numTimePeriods + 0.5]);
        hline(0, 'Color', 'black', 'LineType', '-')
        if (area_ind == 1) && (demand_ind == 1)
            y = ylabel('Average Change in\newlinePopulation Firing Rate\newline(%)');
            y.Rotation = 0;
            y.HorizontalAlignment = 'right';
        else
            set(gca, 'YTickLabel', []);
        end
    end
%%
    function plotPercentSig()
        plotHandle = plot(1:numTimePeriods,  sig(cov_ind, :), '.-', 'MarkerSize', 20, 'LineWidth', 2);
        set(plotHandle, {'Color'}, colorOrder(1:sum(cov_ind), :));
        box off;
        set(gca, 'XTick', 1:numTimePeriods);
        set(gca, 'XTickLabel', strrep(timePeriods, ' ', '\newline'))
        t = text((0.1 + numTimePeriods) * ones(length(levelNames(cov_ind)), 1), sig(cov_ind, end), levelNames(cov_ind));
        if length(plotHandle) == 1,
            set(t, 'Color', get(plotHandle, 'Color'));
        else
            set(t, {'Color'}, get(plotHandle, 'Color'));
        end
        grid on;
        xlim([1 - 0.5, numTimePeriods + 0.5]);
        if params.isAbs,
            ylim([0 50]);
        else
            ylim([0 40]);
        end
        
        title([brainAreas(area_ind), factorsOfInterest(demand_ind)])
        set(gca, 'TickLength', [0, 0]);
        if (area_ind == 1) && (demand_ind == 1),
            y = ylabel('Percentage of\newlineSignificant Neurons');
            y.Rotation = 0;
            y.HorizontalAlignment = 'right';
        else
            set(gca, 'YTickLabel', []);
        end
    end
end