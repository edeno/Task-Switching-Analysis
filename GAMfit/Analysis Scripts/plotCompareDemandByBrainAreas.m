function plotCompareDemandByBrainAreas(modelName, timePeriods, factorsOfInterest, varargin)
inParser = inputParser;
inParser.addRequired('modelName', @iscell);
inParser.addRequired('timePeriod', @iscell);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('colors', [0 0 0], @isnumeric);
inParser.addParameter('onlySig', false, @islogical);

inParser.parse(modelName, timePeriods, varargin{:});
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

for area_ind = 1:numBrainAreas,
    parEst = cell(size(timePeriods));
    parEstAbs = cell(size(timePeriods));
    h = cell(size(timePeriods));
    gam = cell(size(timePeriods));
    for time_ind = 1:numTimePeriods,
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
        subplot(2, numBrainAreas * numFactors, ((2 * demand_ind) - 1) + (area_ind - 1))
        plotEffectSize();
        
        %% Percent Significant
        subplot(2, numBrainAreas * numFactors, ((2 * demand_ind) - 1) + (area_ind - 1) + (numBrainAreas * numFactors))
        plotPercentSig();
    end
    
end

    function [parEst, gam, h] = filterCoef(modelName, timePeriods, brainArea, params)
        [parEst, gam, ~, ~, ~, h] = getCoef(modelName, timePeriods, 'brainArea', brainArea, 'isSim', true, 'subject', params.subject, 'numSim', 1E4);
        
        % bad_ind = (exp(mean(parEst(:, 1, :), 3)) * 1000) <  0.5 | (exp(mean(parEst(:, 1, :), 3)) * 1000) > 1E3; % exclude neurons with < 0.5 Hz firing rate
        % bad_ind = repmat(bad_ind, [1, numLevels, size(parEst, 3)]);
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
        ylim(log([0.85 1.15]))
        set(gca, 'YTick', log(0.85:.05:1.15));
        set(gca, 'YTickLabel', 100 * ([0.85:.05:1.15] - 1));
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
        ylim([0 40]);
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