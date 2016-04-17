function plotPercentSig(comparisonsOfInterest)
workingDir = getWorkingDir();
analysisDir = sprintf('%s/Permutation-Analysis/Analysis', workingDir);
load(sprintf('%s/colllectedPermAnalysis.mat', analysisDir));
brainAreas = {values.brainArea};
timePeriods = values(1).timePeriod;
uniqueBrainAreas = unique(brainAreas);
uniqueTimePeriods = unique(timePeriods, 'stable')';

colors = [27,158,119; ...
    217,95,2; ...
    117,112,179; ...
    231,41,138; ...
    102,166,30; ...
    230,171,2; ...
    166,118,29; ...
    102,102,102] ./ 255;

findBrainAreas = @(x) ismember(brainAreas, x);
findComparison = @(x) ismember(comparisonNames, x);
findTimePeriodIndex = @(x) ismember(uniqueTimePeriods, timePeriods(findComparison(x)));
sig = nan(length(uniqueTimePeriods), length(comparisonsOfInterest), length(uniqueBrainAreas));

for area_ind = 1:length(uniqueBrainAreas),
    avgSig = mean(h(:, findBrainAreas(uniqueBrainAreas(area_ind))), 2) * 100;
    for comp_ind = 1:length(comparisonsOfInterest),
        sig(findTimePeriodIndex(comparisonsOfInterest(comp_ind)), comp_ind, area_ind) = avgSig(findComparison(comparisonsOfInterest(comp_ind)));
    end
end

s = cell(length(uniqueBrainAreas), 1);
figure;
for area_ind = 1:length(uniqueBrainAreas),
    s{area_ind} = subplot(2,1,area_ind);
    p = plot(sig(:, :, area_ind), '.-', 'MarkerSize', 20);
    set(p, {'Color'}, num2cell(colors(1:length(comparisonsOfInterest), :), 2));
    box off;
    set(gca, 'XTick', 1:length(uniqueTimePeriods));
    set(gca, 'XTickLabel', uniqueTimePeriods);
    ylabel('Percent Signficant');
    t = text((0.1 + length(uniqueTimePeriods)) * ones(length(comparisonsOfInterest), 1), sig(end, :, area_ind), comparisonsOfInterest);
    set(t, {'Color'}, num2cell(colors(1:length(comparisonsOfInterest), :), 2))
    title(uniqueBrainAreas(area_ind));
    grid on;
end

s = [s{:}];
ylim = [0 max(cellfun(@max, get(s, {'YLim'})))];
set(s, {'YLim'}, {ylim})


end