function plotSingleNeuronModel(neuronName, covOfInterest, timePeriod, model, varargin)

inParser = inputParser;
inParser.addRequired('neuronName', @ischar);
inParser.addRequired('covOfInterest', @ischar);
inParser.addRequired('timePeriod', @ischar);
inParser.addRequired('model', @ischar);
inParser.parse(neuronName, covOfInterest, timePeriod, model, varargin{:});
params = inParser.Results;

splitName = strsplit(neuronName, '-');
sessionName = splitName{1};

workingDir = getWorkingDir();
pS = load(sprintf('%s/paramSet.mat', workingDir), 'colorInfo', 'covInfo');
colorInfo = pS.colorInfo;
covInfo = pS.covInfo;
modelsDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
mL = load(sprintf('%s/modelList.mat', modelsDir));
modelList = mL.modelList;
gP = load(sprintf('%s/%s/%s_GAMfit.mat', modelsDir, modelList(model), sessionName), 'gamParams');
gamParams = gP.gamParams;

[meanSpiking, time, spikesSample, cInfo, trialTime] = getSingleNeuronData(neuronName, timePeriod, covOfInterest, ...
    'includeFixationBreaks', logical(gamParams.includeFixationBreaks), ...
    'includeIncorrect', logical(gamParams.includeIncorrect), ...
    'includeTimeBeforeZero', logical(gamParams.includeTimeBeforeZero));

numTerms = modelFormulaParse(model);
numTerms = length(numTerms.terms);
colors = values(colorInfo, cInfo.levels);
colors = cat(1, colors{:});

% Exclude trials with less than 50 samples total
n = tabulate(trialTime);
bad_ind = n(:, 2) < 400;

meanSpiking = meanSpiking(:, ~bad_ind);
time = time(~bad_ind);
spikesSample = cellfun(@(x) x(x(:,1) <= max(time), :), spikesSample, 'UniformOutput', false);

f = figure;
set(gcf, 'Position', [1888,230,571,886])
f.Name = sprintf('%s - %s - %s', neuronName, timePeriod, covOfInterest);

s1 = subplot(numTerms + 4,1,1);
plotMeanRate();

legend(cInfo.levels);
title('PSTH from Data');

dataMax = max(meanSpiking);

subplot(numTerms + 4,1,2);
plotRaster();
title('Data');
%%
[meanSpiking, time, spikesSample, cInfo] = getModelSim(neuronName, timePeriod, model, covOfInterest, ...
    'includeFixationBreaks', logical(gamParams.includeFixationBreaks), ...
    'includeIncorrect', logical(gamParams.includeIncorrect), ...
    'includeTimeBeforeZero', logical(gamParams.includeTimeBeforeZero));

meanSpiking = meanSpiking(:, ~bad_ind);
time = time(~bad_ind);
spikesSample = cellfun(@(x) x(x(:,1) <= max(time), :), spikesSample, 'UniformOutput', false);

colors = values(colorInfo, cInfo.levels);
colors = cat(1, colors{:});

s2 = subplot(numTerms + 4,1,3);
plotMeanRate();
set(gca, 'XTickLabel', [])
title('Model Estimated PSTH');

subplot(numTerms + 4,1,4);
plotRaster();
title('Model Estimated Spikes');

modelMax = max(meanSpiking);
m = max([dataMax, modelMax]);
m = ceil(m);

set([s1, s2], 'YLim', [0, m])

tMax = max(time);
%%
[timeEst, time, modelTerms, gam] = getEstOverTime(neuronName, timePeriod, model);
timeEst = cellfun(@(x) x(:, ~bad_ind), timeEst, 'UniformOutput', false);
time = time(~bad_ind);

estLims = cellfun(@(x) quantile(x, [0 1], 2), timeEst, 'UniformOutput', false);
estLims = cat(1, estLims{:});
estLims = quantile(estLims(:), [0, 1]);

levelNames = gam.levelNames(gam.constant_ind);
covNames = gam.covNames(gam.constant_ind);
plotGain()
xlabel('Time (ms)');

%%
    function plotMeanRate()
        plotHandle = plot(time, meanSpiking, 'LineWidth', 2);
        set(plotHandle, {'Color'}, num2cell(colors, 2))
        xlim(quantile(time, [0 1]));
        box off;
        set(gca, 'TickLength', [0, 0]);
        vline(0, 'Color', 'black', 'LineType', '-');
        ylabel('Spikes / s');
    end

    function plotRaster()
        numSamples = cellfun(@(x) max(x(:, 2)), spikesSample, 'UniformOutput', false);
        numSamples = [numSamples{:}];
        numSamples = cumsum(numSamples);
        for level_ind = 1:length(cInfo.levels),
            plot(spikesSample{level_ind}(:, 1), (numSamples(level_ind) - numSamples(1)) + spikesSample{level_ind}(:, 2), '.', 'Color', colors(level_ind, :));
            xlim(quantile(time, [0 1]));
            ylim([0, numSamples(end)])
            set(gca, 'TickLength', [0, 0]);
            set(gca, 'YTickLabel', [])
            box off;
            vline(0, 'Color', 'black', 'LineType', '-');
            hold all;
            ylabel('Trials');
        end
    end

    function plotGain()
        s = cell(numTerms, 1);
        for term_ind = 1:numTerms,
            s{term_ind} = subplot(numTerms + 4,1,4 + term_ind);
            plotHandle = plot(time, timeEst{term_ind}, 'LineWidth', 2);
            termColors = values(colorInfo, levelNames(ismember(covNames, modelTerms.terms(term_ind))));
            termColors = cat(1, termColors{:});
            set(plotHandle, {'Color'}, num2cell(termColors, 2))
            xlim(quantile(time, [0 1]));
            ylim(estLims);
            box off;
            set(gca, 'TickLength', [0, 0]);
            vline(0, 'Color', 'black', 'LineType', '-');
            hline(0, 'Color', 'black', 'LineType', '-');
            title(modelTerms.terms(term_ind));
        end
        s = [s{:}];
        [linearLim, linearTicks, ~, percentTicks] = fixLimits(s, 'isSimple', true);
        set(s, 'YLim', linearLim);
        set(s, 'YTick', linearTicks);
        set(s, 'YTickLabel', percentTicks);
    end

end