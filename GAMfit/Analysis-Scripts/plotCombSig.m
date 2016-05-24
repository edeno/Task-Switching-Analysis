function plotCombSig(modelName, timePeriod, varargin)
inParser = inputParser;
inParser.addRequired('modelName', @ischar);
inParser.addRequired('timePeriod', @ischar);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('brainArea', '*', @ischar);
inParser.addParameter('maxComparisons', [], @isnumeric);

inParser.parse(modelName, timePeriod, varargin{:});
params = inParser.Results;

workingDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', workingDir), 'colorInfo');

[~, gam, ~, ~, ~, h] = getCoef(modelName, timePeriod, 'brainArea', params.brainArea, 'subject', params.subject);
curComparisons = gam.levelNames(2:end);
h = h(:, 2:end);

counter_idx = 1;
numComparisons = length(curComparisons);
if ~isempty(params.maxComparisons) && params.maxComparisons < numComparisons,
    numComparisons = params.maxComparisons;
end

for k = 1:numComparisons
    comb_ind = nchoosek(1:length(curComparisons), k);
    for curComb = 1:size(comb_ind, 1),
        curSig = h(:, comb_ind(curComb, :));
        
        percentSig(counter_idx) = mean(all(curSig, 2)) * 100;
        combNames{counter_idx} = curComparisons(comb_ind(curComb, :));
        
        counter_idx = counter_idx + 1;
        
    end
end

%%
combID = cellfun(@(x) length(x), combNames, 'UniformOutput', false);
combID = [combID{:}];

for comb_ind = 1:numComparisons,
    plotStuff(percentSig(combID == comb_ind), combNames(combID == comb_ind), curComparisons, params, comb_ind, timePeriod, colorInfo)
end

end

function plotStuff(percentSig, combNames, curComparisons, params, comb_ind, timePeriod, colorInfo)
colors = values(colorInfo, cat(1, combNames{:}));
barWidth = 0.5;

f = figure;
ha = tight_subplot(2, 1, [.01 .01], [.1 .01],[.1 .01]);

axes(ha(1));
bar(1:length(percentSig), percentSig);
set(gca, 'XTickLabel', []);
set(gca, 'XTick', 1:length(percentSig));
set(gca, 'TickLength', [0 0]);
box off;
xlim([1 - barWidth, length(percentSig) + barWidth]);
ylabel('Percent Significant');

axes(ha(2));
% width = f.Position(3);
% markerSize = barWidth * (width / length(curComparisons));
%Obtain the axes size (in axpos) in Points

currentunits = get(gca,'Units');
set(ha(2), 'Units', 'Points');
axpos = get(ha(2),'Position');
set(ha(2), 'Units', currentunits);
markerWidth = barWidth * (axpos(3) / length(curComparisons)); % Calculate Marker width in points

ylim([1 - barWidth, length(curComparisons) + barWidth]);
for comparison_ind = 1:length(percentSig),
    comparisonID = find(ismember(curComparisons, combNames{comparison_ind}));
    plot(comparison_ind * ones(size(comparisonID)), comparisonID, 'k.-', 'MarkerSize', markerWidth, 'LineWidth', .1);
    hold all;
    p = plot(comparison_ind, comparisonID, '.', 'MarkerSize', markerWidth);
    set(p, {'Color'}, colors(comparison_ind, :)');
end
set(gca, 'XTick', 1:length(percentSig))
set(gca, 'XTickLabel', []);
set(gca, 'YTick', 1:length(curComparisons));
set(gca, 'YTickLabel', curComparisons);
set(gca, 'TickLength', [0 0])
xlim([1 - barWidth, length(percentSig) + barWidth]);
box off;
grid on;

f.Name = sprintf('%s - %s - Number of Perm: %d', params.brainArea, timePeriod, comb_ind);
end

