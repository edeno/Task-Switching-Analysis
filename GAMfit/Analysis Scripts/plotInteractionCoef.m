function [h] = plotInteractionCoef(timePeriod)
workingDir = getWorkingDir();
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
interactionNames = {'Orientation:Previous Error', 'Orientation:Repetition1', 'Orientation:Repetition2', 'Orientation:Repetition3', 'Orientation:Repetition4'};
avgOrientationIncrease = nan(length(brainAreas), length(interactionNames), 3);
avgOrientationDecrease = nan(length(brainAreas), length(interactionNames), 3);
avgColorIncrease = nan(length(brainAreas), length(interactionNames), 3);
avgColorDecrease = nan(length(brainAreas), length(interactionNames), 3);
avgRuleIncrease = nan(length(brainAreas), length(interactionNames), 3);

for area_ind = 1:length(brainAreas),
    [parEst, gam] = getCoef(modelName, timePeriod, 'brainArea', brainAreas{area_ind}, 'isSim', true);
    orientation_ind = ismember(gam.levelNames, {'Orientation'});
    interactionID = find(ismember(gam.levelNames, interactionNames));
    orientationSelective_ind = parEst(:, orientation_ind, :) > 0;
    colorSelective_ind = parEst(:, orientation_ind, :) < 0;
    bad_ind = abs(parEst) > 5;
    bad_ind(:, 1, :) = true;
    
    orientationIncrease = nan(length(interactionID), size(parEst, 3));
    orientationDecrease = nan(length(interactionID), size(parEst, 3));
    numOrientationIncrease = nan(length(interactionID), size(parEst, 3));
    numOrientationDecrease = nan(length(interactionID), size(parEst, 3));
    colorIncrease = nan(length(interactionID), size(parEst, 3));
    colorDecrease = nan(length(interactionID), size(parEst, 3));
    numColorIncrease = nan(length(interactionID), size(parEst, 3));
    numColorDecrease = nan(length(interactionID), size(parEst, 3));
    ruleIncrease = nan(length(interactionID), size(parEst, 3));
    
    for interaction_ind = 1:length(interactionID),
        for sim_ind = 1:size(parEst, 3),
            
            orientationIncrease_ind = orientationSelective_ind(:, :, sim_ind) & parEst(:, interactionID(interaction_ind), sim_ind) > 0 & ~bad_ind(:, interactionID(interaction_ind), sim_ind);
            orientationDecrease_ind = orientationSelective_ind(:, :, sim_ind) & parEst(:, interactionID(interaction_ind), sim_ind) < 0 & ~bad_ind(:, interactionID(interaction_ind), sim_ind);
            
            colorIncrease_ind = colorSelective_ind(:, :, sim_ind) & parEst(:, interactionID(interaction_ind), sim_ind) < 0 & ~bad_ind(:, interactionID(interaction_ind), sim_ind);
            colorDecrease_ind = colorSelective_ind(:, :, sim_ind) & parEst(:, interactionID(interaction_ind), sim_ind) > 0 & ~bad_ind(:, interactionID(interaction_ind), sim_ind);
            
            orientationIncrease(interaction_ind, sim_ind) = mean(exp(abs(parEst(orientationIncrease_ind, interactionID(interaction_ind), sim_ind))));
            orientationDecrease(interaction_ind, sim_ind) = mean(exp(abs(parEst(orientationDecrease_ind, interactionID(interaction_ind), sim_ind))));
            
            numOrientationIncrease(interaction_ind, sim_ind) = sum(orientationIncrease_ind);
            numOrientationDecrease(interaction_ind, sim_ind) = sum(orientationDecrease_ind);
            
            colorIncrease(interaction_ind, sim_ind) = mean(exp(abs(parEst(colorIncrease_ind, interactionID(interaction_ind), sim_ind))));
            colorDecrease(interaction_ind, sim_ind) = mean(exp(abs(parEst(colorDecrease_ind, interactionID(interaction_ind), sim_ind))));
            
            ruleIncrease(interaction_ind, sim_ind) = mean(exp(abs(parEst(colorIncrease_ind | orientationIncrease_ind, interactionID(interaction_ind), sim_ind))));
            
            numColorIncrease(interaction_ind, sim_ind) = sum(colorIncrease_ind);
            numColorDecrease(interaction_ind, sim_ind) = sum(colorDecrease_ind);
        end
    end
    
    avgOrientationIncrease(area_ind, :, :) = quantile(orientationIncrease, [0.025, 0.5, 0.975], 2);
    avgOrientationDecrease(area_ind, :, :) = quantile(orientationDecrease, [0.025, 0.5, 0.975], 2);
    
    avgColorIncrease(area_ind, :, :) = quantile(colorIncrease, [0.025, 0.5, 0.975], 2);
    avgColorDecrease(area_ind, :, :) = quantile(colorDecrease, [0.025, 0.5, 0.975], 2);
    
    avgRuleIncrease(area_ind, :, :) = quantile(ruleIncrease, [0.025, 0.5, 0.975], 2);
    
end

figure;
for area_ind = 1:length(brainAreas),
    plot(avgRuleIncrease(area_ind, :, 2)', '--.', 'MarkerSize', 30,  'Color', colors(area_ind, :));
    hold all;
    set(gca, 'XTick', 1:length(interactionNames));
    set(gca, 'XTickLabel', interactionNames);
    line(repmat(1:length(interactionNames), 2, 1), squeeze(avgRuleIncrease(area_ind, :, [1 3]))', 'Color', colors(area_ind, :))
end
ylim([1 3]);
xlim([0.5 5.5]);
grid on;
title(timePeriod);

end