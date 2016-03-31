
function plotPermutationAnalysis(comparisonName, timePeriod)
workingDir = getWorkingDir();
loadName = sprintf('%s/Permutation-Analysis/Analysis/colllectedPermAnalysis.mat', workingDir);
load(loadName);
brainAreas = {'dlPFC', 'ACC'};
monkeyNames = {'cc', 'isa'};
filterArea = @(x) ismember({values.brainArea}, x);
filterMonkey = @(x) ismember({values.monkeyName}, x);
filterTimePeriod = @(x) ismember(values(1).timePeriod, x);
filterComparison = @(x) ismember(values(1).comparisonNames, x);

obsDiff = [values.obsDiff];
normObsDiff = [values.normObsDiff];
comparison_ind = filterComparison(comparisonName) & filterTimePeriod(timePeriod);
saveDir = sprintf('%s/Figures/%s/', workingDir, timePeriod);
if ~exist(saveDir, 'dir'),
    mkdir(saveDir);
end

% Both monkeys
f = figure;
for area_ind = 1:length(brainAreas),
    neuron_ind = filterArea(brainAreas{area_ind});
    sig_ind = h(comparison_ind, :);
    
    subplot(6,2, 1 + (area_ind - 1));
    hist(obsDiff(comparison_ind, neuron_ind), 50);
    meanObsDiff = mean(obsDiff(comparison_ind, neuron_ind), 2);
    vline(meanObsDiff, 'Label', sprintf('%.2f', meanObsDiff))
    xlabel({'Raw Difference','(Spikes / s)'});
    titleName = sprintf('%s (%d / %d Sig. Neurons, %.1f%%)', brainAreas{area_ind}, ...
        sum(sig_ind & neuron_ind), ...
        sum(neuron_ind), ...
        100 * sum(sig_ind & neuron_ind) / sum(neuron_ind));
    title(titleName);
    
    subplot(6,2, 3 + (area_ind - 1));
    hist(abs(obsDiff(comparison_ind, neuron_ind)), 50);
    meanAbsObsDiff = mean(abs(obsDiff(comparison_ind, neuron_ind)), 2);
    vline(meanAbsObsDiff, 'Label', sprintf('%.2f', meanAbsObsDiff));
    xlabel({'Abs. Raw Difference','(Spikes / s)'});
    
    subplot(6,2, 5 + (area_ind - 1));
    hist(normObsDiff(comparison_ind, neuron_ind), 50);
    meanNormObsDiff = mean(normObsDiff(comparison_ind, neuron_ind), 2);
    vline(meanNormObsDiff, 'Label', sprintf('%.2f', meanNormObsDiff))
    xlabel({'Norm. Difference','(by Average Firing Rate)'});
    
    subplot(6,2, 7 + (area_ind - 1));
    hist(abs(normObsDiff(comparison_ind, neuron_ind)), 50);
    meanAbsNormObsDiff = mean(abs(normObsDiff(comparison_ind, neuron_ind)), 2);
    vline(meanAbsNormObsDiff, 'Label', sprintf('%.2f', meanAbsNormObsDiff));
    xlabel({'Abs. Norm. Difference','(by Average Firing Rate)'});
    
    subplot(6,2, 9 + (area_ind - 1));
    hist(normObsDiff(comparison_ind, neuron_ind & sig_ind), 50);
    meanNormObsDiff = mean(normObsDiff(comparison_ind, neuron_ind & sig_ind), 2);
    vline(meanNormObsDiff, 'Label', sprintf('%.2f', meanNormObsDiff))
    xlabel({'Sig. Only, Norm. Difference','(by Average Firing Rate)'});
    
    subplot(6,2, 11 + (area_ind - 1));
    hist(abs(normObsDiff(comparison_ind, neuron_ind & sig_ind)), 50);
    meanAbsNormObsDiff = mean(abs(normObsDiff(comparison_ind, neuron_ind & sig_ind)), 2);
    vline(meanAbsNormObsDiff, 'Label', sprintf('%.2f', meanAbsNormObsDiff));
    xlabel({'Sig. Only, Abs. Norm. Difference','(by Average Firing Rate)'});
end
f.Name = sprintf('%s - Both Monkeys: %s', timePeriod, comparisonName);
saveName = sprintf('%s/%s_Both Monkeys_%s', saveDir, timePeriod, comparisonName);
saveas(f, saveName);

% Individual monkeys
for monkey_ind = 1:length(monkeyNames),
    f = figure;
    for area_ind = 1:length(brainAreas),
        neuron_ind = filterArea(brainAreas{area_ind}) & filterMonkey(monkeyNames{monkey_ind});
        sig_ind = h(comparison_ind, :);
        
        subplot(6,2, 1 + (area_ind - 1));
        hist(obsDiff(comparison_ind, neuron_ind), 50);
        meanObsDiff = mean(obsDiff(comparison_ind, neuron_ind), 2);
        vline(meanObsDiff, 'Label', sprintf('%.2f', meanObsDiff))
        xlabel({'Raw Difference','(Spikes / s)'});
        titleName = sprintf('%s (%d / %d Sig. Neurons, %.1f%%)', brainAreas{area_ind}, ...
            sum(sig_ind & neuron_ind), ...
            sum(neuron_ind), ...
            100 * sum(sig_ind & neuron_ind) / sum(neuron_ind));
        title(titleName);
        
        subplot(6,2, 3 + (area_ind - 1));
        hist(abs(obsDiff(comparison_ind, neuron_ind)), 50);
        meanAbsObsDiff = mean(abs(obsDiff(comparison_ind, neuron_ind)), 2);
        vline(meanAbsObsDiff, 'Label', sprintf('%.2f', meanAbsObsDiff));
        xlabel({'Abs. Raw Difference','(Spikes / s)'});
        
        subplot(6,2, 5 + (area_ind - 1));
        hist(normObsDiff(comparison_ind, neuron_ind), 50);
        meanNormObsDiff = mean(normObsDiff(comparison_ind, neuron_ind), 2);
        vline(meanNormObsDiff, 'Label', sprintf('%.2f', meanNormObsDiff))
        xlabel({'Norm. Difference','(by Average Firing Rate)'});
        
        subplot(6,2, 7 + (area_ind - 1));
        hist(abs(normObsDiff(comparison_ind, neuron_ind)), 50);
        meanAbsNormObsDiff = mean(abs(normObsDiff(comparison_ind, neuron_ind)), 2);
        vline(meanAbsNormObsDiff, 'Label', sprintf('%.2f', meanAbsNormObsDiff));
        xlabel({'Abs. Norm. Difference','(by Average Firing Rate)'});
        
        subplot(6,2, 9 + (area_ind - 1));
        hist(normObsDiff(comparison_ind, neuron_ind & sig_ind), 50);
        meanNormObsDiff = mean(normObsDiff(comparison_ind, neuron_ind & sig_ind), 2);
        vline(meanNormObsDiff, 'Label', sprintf('%.2f', meanNormObsDiff))
        xlabel({'Sig. Only, Norm. Difference','(by Average Firing Rate)'});
        
        subplot(6,2, 11 + (area_ind - 1));
        hist(abs(normObsDiff(comparison_ind, neuron_ind & sig_ind)), 50);
        meanAbsNormObsDiff = mean(abs(normObsDiff(comparison_ind, neuron_ind & sig_ind)), 2);
        vline(meanAbsNormObsDiff, 'Label', sprintf('%.2f', meanAbsNormObsDiff));
        xlabel({'Sig. Only, Abs. Norm. Difference','(by Average Firing Rate)'});
    end
    f.Name = sprintf('%s - Monkey %s: %s', timePeriod, monkeyNames{monkey_ind}, comparisonName);
    saveName = sprintf('%s/%s_Monkey %s_%s', saveDir, timePeriod, monkeyNames{monkey_ind}, comparisonName);
    saveas(f, saveName);
end

%%
% avgFiringRate = [values.avgFiringRate];
% f = figure;
% for area_ind = 1:length(brainAreas),
%
%     subplot(3, 2, 1 + (area_ind - 1));
%     neuron_ind = filterArea(brainAreas{area_ind});
%     hist(avgFiringRate(neuron_ind), 50);
%     vline(quantile(avgFiringRate(neuron_ind), [.25 .5 .75]))
%     xlim([0 max(avgFiringRate)])
%     title(brainAreas{area_ind});
%
%     subplot(3, 2, 3 + (area_ind - 1));
%     neuron_ind = filterArea(brainAreas{area_ind}) & filterMonkey(monkeyNames{1});
%     hist(avgFiringRate(neuron_ind), 50);
%     vline(quantile(avgFiringRate(neuron_ind), [.25 .5 .75]))
%     xlim([0 max(avgFiringRate)])
%     title(monkeyNames{1});
%
%     subplot(3, 2, 5 + (area_ind - 1));
%     neuron_ind = filterArea(brainAreas{area_ind}) & filterMonkey(monkeyNames{2});
%     hist(avgFiringRate(neuron_ind), 50);
%     vline(quantile(avgFiringRate(neuron_ind), [.25 .5 .75]))
%     xlim([0 max(avgFiringRate)])
%     title(monkeyNames{2});
% end
% f.Name = sprintf('%s: Average Firing Rate', timePeriod);


end
