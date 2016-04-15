% SigComb
clear variables
comparisonsOfInterest = {'Orientation - Color', ...
    'Previous Error - No Previous Error', ...
    'Incongruent - Congruent', ...
    'Left - Right', ...
    'Repetition1 - Repetition5+', ...
    'Repetition2 - Repetition5+', ...
    'Repetition3 - Repetition5+', ...
    'Repetition4 - Repetition5+', ...
    };
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
findTimePeriods = @(x) ismember(timePeriods, x);
barWidth = 0.8;

for area_ind = 1:length(uniqueBrainAreas),
    for timePeriod_ind = 1:length(uniqueTimePeriods),
        clear percentSig combNames;
        curComparisons = comparisonNames(findTimePeriods(uniqueTimePeriods(timePeriod_ind)));
        curComparisons = curComparisons(ismember(curComparisons, comparisonsOfInterest));
        curComparisons = curComparisons(end:-1:1);
        
        counter_idx = 1;
        
        for k = 1:length(curComparisons)
            comb_ind = nchoosek(1:length(curComparisons), k);
            for curComb = 1:size(comb_ind, 1),
                curSig = h(findComparison(curComparisons(comb_ind(curComb, :))) & findTimePeriods(uniqueTimePeriods(timePeriod_ind)), findBrainAreas(uniqueBrainAreas(area_ind)));
                
                percentSig(counter_idx) = mean(all(curSig, 1)) * 100;
                combNames{counter_idx} = curComparisons(comb_ind(curComb, :));
                
                counter_idx = counter_idx + 1;
                
            end
        end
        f = figure;
        ha = tight_subplot(2, 1, [.01 .01], [.1 .01],[.2 .01]);

        axes(ha(1));
        bar(percentSig);
        set(gca, 'XTickLabel', []);
        set(gca, 'XTick', 1:length(percentSig));
        set(gca, 'TickLength', [0 0]);
        grid on;
        box off;
        xlim([1 - barWidth, length(percentSig) + barWidth]);
        ylabel('Percent Significant');
        
        axes(ha(2));
        ylim([1 - barWidth, length(curComparisons) + barWidth]);
        for comparison_ind = 1:length(percentSig),
            time_ind = find(ismember(curComparisons, combNames{comparison_ind}));
            plot(comparison_ind * ones(size(time_ind)), time_ind, 'k.-', 'MarkerSize', 25);
            hold all;
            p = plot(comparison_ind, time_ind, '.', 'MarkerSize', 25);
            set(p, {'Color'}, num2cell(colors(time_ind, :), 2));
        end
        set(gca, 'XTick', 1:length(percentSig))
        set(gca, 'XTickLabel', []);
        set(gca, 'YTick', 1:length(curComparisons));
        set(gca, 'YTickLabel', curComparisons);
        set(gca, 'TickLength', [0 0])
        xlim([1 - barWidth, length(percentSig) + barWidth]);
        grid on;
        box off;
        f.Name = sprintf('%s - %s', uniqueBrainAreas{area_ind}, uniqueTimePeriods{timePeriod_ind});
    end
end