function plotCompareDemandByBrainAreas(modelName, timePeriods, varargin)
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
demandFactors = {'Previous Error History', 'Rule Repetition', 'Congruency'};

numTimePeriods = length(timePeriods);
figure;

for area_ind = 1:length(brainAreas),
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
    
    for demand_ind = 1:length(demandFactors),
        cov_ind = ismember(covNames, demandFactors{demand_ind});
        %% Effect Size
        subplot(3, 4, (4 * (demand_ind - 1)) + area_ind)
        plotEffectSize();
        
        %% Percent Significant
        subplot(3, 4, (4 * (demand_ind - 1)) + area_ind + 2)
        plotPercentSig();
    end
    
end

    function [parEst, gam, h] = filterCoef(modelName, timePeriods, brainArea, params)
        [parEst, gam, ~, ~, ~, h] = getCoef(modelName, timePeriods, 'brainArea', brainArea, 'isSim', true, 'subject', params.subject, 'numSim', 1E4);
        
        numLevels = length(gam.levelNames);
        
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
        plotHandle{demand_ind} = plot(1:numTimePeriods, squeeze(timeEst(cov_ind, 2, :)), '.-', 'MarkerSize', 20);
        hold all;
        l = cell(sum(cov_ind), 1);
        lID = find(cov_ind);
        for l_ind = 1:length(lID),
            l{l_ind} = line(repmat(1:numTimePeriods, [2 1]), squeeze(timeEst(lID(l_ind), [1 3], :)));
            set(l{l_ind}, 'Color', get(plotHandle{demand_ind}(l_ind), 'Color'));
        end
        box off;
        grid on;
        t = text((0.1 + numTimePeriods) * ones(length(levelNames(cov_ind)), 1), timeEst(cov_ind, 2, end), levelNames(cov_ind));
        if length(plotHandle{demand_ind}) == 1,
            set(t, 'Color', get(plotHandle{demand_ind}, 'Color'));
        else
            set(t, {'Color'}, get(plotHandle{demand_ind}, 'Color'));
        end
        
        title([brainAreas(area_ind), demandFactors(demand_ind)])
        ylim(log([.9 1.1]))
        set(gca, 'YTick', log(0.9:.05:1.1));
        set(gca, 'YTickLabel', 100 * ([0.9:.05:1.1] - 1));
        set(gca, 'TickLength', [0, 0]);
        set(gca, 'XTickLabel', strrep(timePeriods, ' ', '\newline'))
        xlim([1 - 0.5, numTimePeriods + 0.5]);
        hline(0, 'Color', 'black', 'LineType', '-')
        ylabel('Change in Firing Rate (%)')
    end
%%
    function plotPercentSig()
        plotHandle{demand_ind} = plot(1:numTimePeriods,  sig(cov_ind, :), '.-', 'MarkerSize', 20);
        box off;
        set(gca, 'XTick', 1:numTimePeriods);
        set(gca, 'XTickLabel', strrep(timePeriods, ' ', '\newline'))
        t = text((0.1 + numTimePeriods) * ones(length(levelNames(cov_ind)), 1), sig(cov_ind, end), levelNames(cov_ind));
        if length(plotHandle{demand_ind}) == 1,
            set(t, 'Color', get(plotHandle{demand_ind}, 'Color'));
        else
            set(t, {'Color'}, get(plotHandle{demand_ind}, 'Color'));
        end
        grid on;
        xlim([1 - 0.5, numTimePeriods + 0.5]);
        ylim([0 50]);
        title([brainAreas(area_ind), demandFactors(demand_ind)])
        set(gca, 'TickLength', [0, 0]);
        ylabel('Percentage of Significant Neurons')
    end
end