function plotCorrelateNeuronsToBehavior(modelName, timePeriod, varargin)

inParser = inputParser;
inParser.addRequired('modelName', @ischar);
inParser.addRequired('timePeriod', @ischar);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('onlySig', false, @islogical);

inParser.parse(modelName, timePeriod, varargin{:});
params = inParser.Results;
load('paramSet.mat', 'sessionNames');
if ~strcmp(params.subject, '*'),
    keep_ind = regexp(sessionNames, sprintf('%s*', params.subject));
    keep_ind = cellfun(@(x) ~isempty(x), keep_ind);
    sessionNames = sessionNames(keep_ind);
end

parEstCorrect = [];
parEstNeuron = [];
neuronNames = [];
neuronBrainAreas = [];
pValNeuron = [];
pValCorrect = [];

for session_ind = 1:length(sessionNames),
    [parEstN, ~, nNames, nBrainAreas, pNeuron, ~] = getCoef(modelName, timePeriod, 'sessionName', sessionNames{session_ind});
    
    bad_ind = abs(parEstN) > 10;
    bad_ind(:, 1, :) = false;
    
    parEstN(bad_ind) = NaN;
    
    [parEstC, ~, stats, gam] = getBehaviorCoef(modelName, 'sessionName', sessionNames{session_ind});
    pCorrect = stats.p;
    parEstC = repmat(parEstC', [length(nNames), 1]);
    pCorrect = repmat(pCorrect', [length(nNames), 1]);
    
    bad_ind = abs(parEstC) > 100;
    bad_ind(:, 1, :) = false;
    
    parEstC(bad_ind) = NaN;
    
    
    parEstCorrect = cat(1, parEstCorrect, (parEstC(:, 2:end)));
    parEstNeuron = cat(1, parEstNeuron, (parEstN(:, 2:end)));
    
    neuronNames = cat(2, neuronNames, nNames);
    neuronBrainAreas = cat(2, neuronBrainAreas, nBrainAreas);
    pValNeuron = cat(1, pValNeuron, pNeuron(:, 2:end));
    pValCorrect = cat(1, pValCorrect, pCorrect(:, 2:end));
    
end

levelNames = gam.levelNames(2:end);

alpha = 0.05;

%%
sortedP = sort(pValNeuron(:));
numP = length(pValNeuron(:));

thresholdLine = ([1:numP]' / numP) * alpha;
threshold_ind = find(sortedP <= thresholdLine, 1, 'last');
threshold = sortedP(threshold_ind);

hNeuron = pValNeuron < threshold;

%%
sortedP = sort(pValCorrect(:));
numP = length(pValCorrect(:));

thresholdLine = ([1:numP]' / numP) * alpha;
threshold_ind = find(sortedP <= thresholdLine, 1, 'last');
threshold = sortedP(threshold_ind);

hCorrect =  pValCorrect < threshold;
%%
if params.onlySig,
    % parEstCorrect(~hCorrect) = NaN;
    parEstNeuron(~hNeuron) = NaN;
end
%%
brainAreas = {'ACC', 'dlPFC'};
isBrainArea = @(x) ismember(neuronBrainAreas, x);

for area_ind = 1:length(brainAreas),
    subs = numSubplots(length(levelNames));
    f = figure;
    for plot_ind = 1:length(levelNames),
        subplot(subs(1), subs(2), plot_ind);
        plot(parEstCorrect(isBrainArea(brainAreas{area_ind}), plot_ind), parEstNeuron(isBrainArea(brainAreas{area_ind}), plot_ind), '.', 'MarkerSize', 15)
        title(levelNames{plot_ind});
        xlim([-2 2]);
        ylim([-2 2]);
        lsline;
        hline(0, 'Color', 'black', 'LineType', '-');
        vline(0, 'Color', 'black', 'LineType', '-');
    end
    f.Name = sprintf('%s - %s - %s', brainAreas{area_ind}, timePeriod, params.subject);
end
end