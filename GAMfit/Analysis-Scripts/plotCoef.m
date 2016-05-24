function [h] = plotCoef(timePeriod)
workingDir = getWorkingDir();
modelsDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
m = load(sprintf('%s/modelList.mat', modelsDir));
modelList = m.modelList;
modelName = 'Rule * Previous Error + Rule * Rule Repetition';
permAnalysis = load(sprintf('%s/Permutation-Analysis/Analysis/colllectedPermAnalysis.mat', workingDir));
values = permAnalysis.values;
values = [values(:)];
filterArea = @(x) ismember({values.brainArea}, x);
filterMonkey = @(x) ismember({values.monkeyName}, x);
filterTimePeriod = @(x) ismember(values(1).timePeriod, x);
filterComparison = @(x) ismember(values(1).comparisonNames, x);
hRulePerm = [values.h];
colors = [228,26,28; ...
    77,175,74] ./ 255;
brainAreas = {'dlPFC', 'ACC'};
monkeyNames = {'cc', 'isa'};
h = cell(length(brainAreas),1);

figure;
for area_ind = 1:length(brainAreas),
    [parEst, gam, neuronNames, ~, p] = getCoef(modelName, timePeriod, 'brainArea', brainAreas{area_ind}, 'isSim', true);
    hRulePerm = cellfun(@(x) permAnalysis.permAnalysis(x).h(filterComparison('Orientation - Color') & filterTimePeriod(timePeriod)), neuronNames, 'UniformOutput', false);
    hRulePerm = [hRulePerm{:}];
    avgFiringRate = cellfun(@(x) permAnalysis.permAnalysis(x).avgFiringRate, neuronNames, 'UniformOutput', false);
    avgFiringRate = [avgFiringRate{:}];
    
    prevError_ind = ismember(gam.levelNames, 'Orientation:Previous Error');
    ruleRep_ind = ismember(gam.levelNames, {'Orientation:Repetition1', ...
        'Orientation:Repetition2', 'Orientation:Repetition3', 'Orientation:Repetition4'});
    
    % Set extreme estimates to NaN
    bad_ind = abs(parEst) > 5;
    bad_ind(:, 1, :) = false;
    parEst(bad_ind) = NaN;
    bootEst = @(x) squeeze(quantile(exp(nanmean(x, 1)), [0.025, 0.5, 0.975], 3));    
    
    subplot(4,2,1);
    plotEffect(bootEst(parEst(:, ruleRep_ind, :)));
    title('Mean Effect')
    
    subplot(4,2,2);
    plotEffect(bootEst(abs(parEst(:, ruleRep_ind, :))));
    title('Abs. Mean Effect')
    
    subplot(4,2,3);
    higherFiring_ind = avgFiringRate > 0.5;
    plotEffect(bootEst(parEst(higherFiring_ind, ruleRep_ind, :)));
    title('Mean Effect, neurons > 0.5 Hz firing rate')
    
    subplot(4,2,4);
    plotEffect(bootEst(abs(parEst(higherFiring_ind, ruleRep_ind, :))));
    title('Abs. Mean Effect, neurons > 0.5 Hz firing rate')
    
    subplot(4,2,5);
    plotEffect(bootEst(parEst(hRulePerm, ruleRep_ind, :)));
    title('Mean Effect, sig. Rule Only')
    
    subplot(4,2,6);
    plotEffect(bootEst(abs(parEst(hRulePerm, ruleRep_ind, :))));
    title('Abs. Mean Effect, sig. Rule Only')
    
    subplot(4,2,7);
    plotEffect(bootEst(parEst(hRulePerm, ruleRep_ind, :)));
    title('Mean Effect, sig. Rule Only & neurons > 0.5 Hz firing rate')
    
    subplot(4,2,8);
    plotEffect(bootEst(abs(parEst(hRulePerm, ruleRep_ind, :))));
    title('Abs. Mean Effect, sig. Rule Only & neurons > 0.5 Hz firing rate')
    
    alpha = 0.05;
    sortedP = sort(p(:));
    numP = length(p(:));
    
    thresholdLine = ([1:numP]' / numP) * alpha;
    threshold_ind = find(sortedP <= thresholdLine, 1, 'last');
    threshold = sortedP(threshold_ind);
    
    h{area_ind} = reshape(p < threshold, size(p));
    
end

    function plotEffect(effect)
        if strcmp(brainAreas{area_ind}, 'ACC'),
            x = [1:length(effect)] + 0.00;
        else
            x = [1:length(effect)] - 0.00;
        end
        plot(x, effect(:, 2), '.-', 'Color', colors(area_ind, :), 'LineWidth', 2); hold all;
        t = text(length(effect), effect(end, 2), brainAreas{area_ind});
        t.Color = colors(area_ind, :)';
        line(repmat(x', 1, 2)', effect(:, [1 3])', 'Color', colors(area_ind, :))
        box off;
        hline(1, 'Color', 'black', 'LineType', '-');
        set(gca, 'XTick', 1:length(effect));
        xlim([0.5, length(effect) + 0.5]);
    end

end