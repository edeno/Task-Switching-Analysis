function plotSingleNeuronData(neuronName, covOfInterest, timePeriods, varargin)

inParser = inputParser;
inParser.addRequired('neuronName', @ischar);
inParser.addRequired('covOfInterest', @ischar);
inParser.addRequired('timePeriods', @iscell);
inParser.parse(neuronName, covOfInterest, timePeriods, varargin{:});
params = inParser.Results;

splitName = strsplit(neuronName, '-');
sessionName = splitName{1};

workingDir = getWorkingDir();
pS = load(sprintf('%s/paramSet.mat', workingDir), 'colorInfo', 'sessionNames', 'neuronInfo');
colorInfo = pS.colorInfo;
neuronInfo = pS.neuronInfo;
sessionNames = pS.sessionNames;
b = load(sprintf('%s/Behavior/behavior.mat', workingDir), 'behavior');
behavior = b.behavior{ismember(sessionNames, sessionName)};
numTimePeriods = length(timePeriods);

f = figure;
width = 600 * numTimePeriods;
height = 300 * 2;
set(f, 'Position', [1888,230,width,height])
s = cell(numTimePeriods, 1);

for timePeriod_ind = 1:numTimePeriods,
    
    [meanSpiking, time, spikesSample, cInfo, trialTime] = getSingleNeuronData(neuronName, timePeriods{timePeriod_ind}, covOfInterest, ...
        'includeFixationBreaks', false, ...
        'includeIncorrect', false, ...
        'includeTimeBeforeZero', true);
    
    colors = values(colorInfo, cInfo.levels);
    colors = cat(1, colors{:});
    
    switch (timePeriods{timePeriod_ind})
        case 'Rule Stimulus'
            bad_ind = unique(trialTime) >= nanmean(behavior('Preparation Time'));
        case 'Stimulus Response'
            bad_ind = unique(trialTime) >= nanmean(behavior('Reaction Time'));
        otherwise
            % Exclude trials with less than 50 samples total
            n = tabulate(trialTime);
            bad_ind = n(:, 2) < 400;
    end
    bad_ind = bad_ind | unique(trialTime) < -100;
    
    
    meanSpiking = meanSpiking(:, ~bad_ind);
    time = time(~bad_ind);
    spikesSample = cellfun(@(x) x(x(:,1) <= max(time), :), spikesSample, 'UniformOutput', false);
    
    s{timePeriod_ind} = subplot(2, numTimePeriods, timePeriod_ind);
    plotMeanRate();
    
    title('PSTH from Data');
    
    dataMax(timePeriod_ind) = max(meanSpiking(:));
    
    subplot(2, numTimePeriods, numTimePeriods + timePeriod_ind);
    plotRaster();
    title('Data');
end

% legend(cInfo.levels);

m = max(dataMax);
m = ceil(m);

set([s{:}], 'YLim', [0, m]);
set([s{:}], 'YTick', [0, m]);

for k = 1:(numTimePeriods * 2),
    subplot(2, numTimePeriods, k);
    if min(time) < 0,
        vline(0, 'Color', 'Black', 'LineType', '-');
    end
end

f.Name = sprintf('%s %s - %s', neuronInfo(neuronName).brainArea, neuronName, covOfInterest);
%%
    function plotMeanRate()
        plotHandle = plot(time, meanSpiking, 'LineWidth', 2);
        set(plotHandle, {'Color'}, num2cell(colors, 2))
        xlim(quantile(time, [0 1]));
        box off;
        set(gca, 'TickLength', [0, 0]);
        ylabel('Spikes / s');
        set(gca, 'FontName', 'Arial');
    end

    function plotRaster()
        numSamples = cellfun(@(x) max(x(:, 2)), spikesSample, 'UniformOutput', false);
        numSamples = [numSamples{:}];
        numSamples = cumsum(numSamples);
        for level_ind = 1:length(numSamples),
            plot(spikesSample{level_ind}(:, 1), (numSamples(level_ind) - numSamples(1)) + spikesSample{level_ind}(:, 2), '.', 'Color', colors(level_ind, :));
            xlim(quantile(time, [0 1]));
            ylim([0, numSamples(end)])
            set(gca, 'TickLength', [0, 0]);
            set(gca, 'YTickLabel', [])
            box off;
            hold all;
            ylabel('Trials');
            set(gca, 'FontName', 'Arial');
        end
    end

end