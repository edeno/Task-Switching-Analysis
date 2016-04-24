function plotSplinePopFit(model, timePeriod, varargin)
inParser = inputParser;
inParser.addRequired('model', @ischar);
inParser.addRequired('timePeriod', @ischar);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('brainArea', '*', @ischar);

inParser.parse(model, timePeriod, varargin{:});
params = inParser.Results;

stat = @(s) nanmean(s, 4);
bootEst = @(s) quantile(s, [0.025, 0.5, 0.975], 3);

[timeEst, time] = getSplineCoef(model, timePeriod, 'brainArea', params.brainArea, 'isSim', true, 'subject', params.subject);

prevError = cat(4, timeEst.Previous_Error);
ruleRep = cat(4, timeEst.Rule_Repetition);
rule = cat(4, timeEst.Rule);

ruleRep(abs(ruleRep) > 10) = NaN;
rule(abs(rule) > 10) = NaN;
prevError(abs(prevError) > 10) = NaN;

if strcmp(unique({timeEst.subject}), 'isa') && strcmp(timePeriod, 'Rule Stimulus'),
    bad_ind = time > 345 | time < -50;
    prevError = prevError(:, ~bad_ind, :, :);
    ruleRep = ruleRep(:, ~bad_ind, :, :);
    rule = rule(:, ~bad_ind, :, :);
    time = time(~bad_ind);
else
     bad_ind = time < -50;
    prevError = prevError(:, ~bad_ind, :, :);
    ruleRep = ruleRep(:, ~bad_ind, :, :);
    rule = rule(:, ~bad_ind, :, :);
    time = time(~bad_ind);
end

colorOrder = [ ...
    37,52,148; ...
    44,127,184; ...
    65,182,196; ...
    127,205,187; ...
    199,233,180; ...
    ] ./ 255;

%% Average Population Change
f = figure;
f.Name = sprintf('%s - %s - %s', params.brainArea, params.timePeriod, params.subject);
subplot(3,3,1);
plotPopMean(abs(rule))
set(gca, 'YLim', log([1 1.4]));
set(gca, 'YTick', log(1:0.05:1.4));
set(gca, 'YTickLabel', ((1:0.05:1.4) - 1) * 100);
vline(0, 'Color', 'black', 'LineType', '-');

title('Rule');

subplot(3,3,2);
plotPopMean(ruleRep)
title('Rule Repetition');

subplot(3,3,3);
plotPopMean(prevError)
title('Previous Error');

%% Number of Significant by Time
subplot(3,3,4);
plotPopSig(rule)

subplot(3,3,5);
plotPopSig(ruleRep)

subplot(3,3,6);
plotPopSig(prevError)

%% Time to first significance
subplot(3,3,7);
plotTimeToSig(rule)

subplot(3,3,8);
plotTimeToSig(ruleRep)

subplot(3,3,9);
plotTimeToSig(prevError)

%%
    function plotPopMean(est)
        data = bootEst(stat(est));
        numLevels = size(data, 1);
        for level_ind = 1:numLevels,
            plot(time, squeeze((data(level_ind, :, 2, :))), 'LineWidth', 2, 'Color', colorOrder(level_ind, :));
            hold all;
            plot(time, squeeze((data(level_ind, :, [1 3], :))), 'LineWidth', 0.5, 'Color', colorOrder(level_ind, :));
        end
        
        set(gca, 'YLim', log([0.9 1.2]));
        set(gca, 'YTick', log(0.9:0.05:1.2));
        set(gca, 'YTickLabel', ((0.9:0.05:1.2) - 1) * 100);
        xlim([-50, max(time)]);
        vline(0, 'Color', 'black', 'LineType', '-');
        hline(0, 'Color', 'black', 'LineType', '-');
    end
%%
    function plotPopSig(est)
        data = bootEst(est);
        numLevels = size(data, 1);
        h = data(:, :, 1, :) > 0 | data(:, :, 3, :) < 0;
        plotHandle = plot(time, squeeze(mean(h, 4)) * 100);
        colors = colorOrder(1:numLevels, :);
        set(plotHandle, {'Color'}, num2cell(colors, 2));
        xlim([-50, max(time)]);
        ylim([0 60])
        vline(0, 'Color', 'black', 'LineType', '-');
    end
%%
    function plotTimeToSig(est)
        data = bootEst(est);
        numLevels = size(data, 1);
        h = data(:, :, 1, :) > 0 | data(:, :, 3, :) < 0;
        timeSig = nan(size(h, 4), numLevels);
        NUM_CONSEC = 3;
        
        for level_ind = 1:numLevels,
            for neuron_ind = 1:size(h, 4),
                timeSig(neuron_ind, level_ind) = firstTimeSig(squeeze(h(level_ind, :, :, neuron_ind)), NUM_CONSEC);
            end
            plot(mean(timeSig(:, level_ind)), level_ind, '.', 'MarkerSize', 20, 'Color', colorOrder(level_ind, :))
            hold all;
            ci = ([-1 1] * 1.96 * std(timeSig(:, level_ind)) / sqrt(length(timeSig(:, level_ind)))) + mean(timeSig(:, level_ind)) * [1 1];
            l = line(ci, [level_ind level_ind]);
            l.Color = colorOrder(level_ind, :);
            xlim([-50, max(time)]);
            normHist = (level_ind - 0.5) + histc(timeSig(:, level_ind), time) ./ max(histc(timeSig(:, level_ind), time));
            plot(time, normHist, 'LineWidth' , 1, 'Color', colorOrder(level_ind, :))
        end
        ylim([0.5, numLevels + 0.5]);
        vline(0, 'Color', 'black', 'LineType', '-');
        %%
        function [sigTime] = firstTimeSig(x, numConsec)
            time_ind = find(conv(double(x), ones(numConsec, 1)) == numConsec, 1) - (numConsec - 1);
            if isempty(time_ind)
                sigTime = time(end);
            else
                sigTime = time(time_ind);
            end
        end
        
    end

end

