function plotCombSig(modelName, timePeriod, varargin)
inParser = inputParser;
inParser.addRequired('modelName', @ischar);
inParser.addRequired('timePeriod', @ischar);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('brainArea', '*', @ischar);

inParser.parse(modelName, timePeriod, varargin{:});
params = inParser.Results;

 [~, gam, ~, ~, ~, h] = getCoef(modelName, timePeriod, 'brainArea', params.brainArea, 'subject', params.subject);
 curComparisons = gam.levelNames(2:end);
 h = h(:, 2:end);
 
 counter_idx = 1;

for k = 1:length(curComparisons)
    comb_ind = nchoosek(1:length(curComparisons), k);
    for curComb = 1:size(comb_ind, 1),
        curSig = h(:, comb_ind(curComb, :));
        
        percentSig(counter_idx) = mean(all(curSig, 2)) * 100;
        combNames{counter_idx} = curComparisons(comb_ind(curComb, :));
        
        counter_idx = counter_idx + 1;
        
    end
end

%%
numFactors = cellfun(@(x) length(x), combNames, 'UniformOutput', false);
numFactors = [numFactors{:}];
colors = [27,158,119; ...
    37,52,148; ...
    44,127,184; ...
    65,182,196; ...
    127,205,187; ...
    199,233,180; ...
        37,52,148; ...
    44,127,184; ...
    65,182,196; ...
    127,205,187; ...
    ] ./ 255;
barWidth = 0.8;
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
vline(find(diff(numFactors)) + .5, 'Color', 'black', 'LineType', '-');

axes(ha(2));
ylim([1 - barWidth, length(curComparisons) + barWidth]);
for comparison_ind = 1:length(percentSig),
    time_ind = find(ismember(curComparisons, combNames{comparison_ind}));
%     plot(comparison_ind * ones(size(time_ind)), time_ind, 'k.-', 'MarkerSize', 5, 'LineWidth', .1);
    hold all;
    p = plot(comparison_ind, time_ind, '.', 'MarkerSize', 5);
    set(p, {'Color'}, num2cell(colors(time_ind, :), 2));
end
set(gca, 'XTick', 1:length(percentSig))
set(gca, 'XTickLabel', []);
set(gca, 'YTick', 1:length(curComparisons));
set(gca, 'YTickLabel', curComparisons);
set(gca, 'TickLength', [0 0])
xlim([1 - barWidth, length(percentSig) + barWidth]);
box off;
vline(find(diff(numFactors)) + .5, 'Color', 'black', 'LineType', '-');
end