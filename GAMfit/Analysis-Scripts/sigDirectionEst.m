function sigDirectionEst(timePeriods, models)

[parEst, h, neuronBrainAreas, gam] = getData(models, timePeriods);

colors = [102,189,99; 166,217,10; 244,109,67; 253,174,97] ./ 255;

posEst = cell(size(h));
negEst = cell(size(h));

for k = 1:length(h),
    sigMask = double(h{k});
    sigMask(sigMask ~= 1) = NaN;
    sigEst = sigMask .* parEst{k};
    
    posSigMask = double(sigEst > 0);
    posSigMask(posSigMask ~= 1) = NaN;
    negSigMask = double(sigEst < 0);
    negSigMask(negSigMask ~= 1) = NaN;
    
    posEst{k} = posSigMask .* parEst{k};
    negEst{k} = negSigMask .* parEst{k};
end

s1 = subplot(1,2,1);
plotSigEst('Rule Repetition', negEst, posEst, gam, colors, neuronBrainAreas);
title('Rule Repetition');
s2 = subplot(1,2,2);
plotSigEst('Previous Error History', negEst, posEst, gam, colors, neuronBrainAreas);
title('Error History');

[linearLim, linearTicks, ~, percentTicks] = fixLimits([s1, s2], 'expTickInterval', .25);
set([s1, s2], 'YLim', [0, linearLim(end)]);
set([s1, s2], 'YTick', linearTicks);
set([s1, s2], 'YTickLabel', percentTicks);

end
function plotSigEst(cov, negEst, posEst, gam, colors, neuronBrainAreas)

getBrainArea = @(brainArea) ismember(neuronBrainAreas, brainArea);
brainAreas = {'ACC', 'dlPFC'};
covNames = gam(end).covNames;
levelNames = gam(end).levelNames(ismember(covNames, cov));
cov_ind = arrayfun(@(x) ismember(x.covNames, cov), gam, 'UniformOutput', false);

for area_ind = 1:length(brainAreas),
    est = [cellfun(@(x,y) nanmean(x(getBrainArea(brainAreas{area_ind}), y)), posEst, cov_ind', 'UniformOutput', false); ...
        cellfun(@(x,y) nanmean(x(getBrainArea(brainAreas{area_ind}), y)), negEst, cov_ind', 'UniformOutput', false);];
    
    est = cell2mat(est)';
    
    if strcmp(brainAreas{area_ind}, 'ACC'),
        plotHandle = plot(abs(est), '.-', 'MarkerSize', 20);    
    else
        plotHandle = plot(abs(est), '.-', 'MarkerSize', 40);    
    end
    
    hold all;
    set(gca, 'XTick', 1:length(levelNames));
    set(gca, 'XTickLabel', levelNames);
    xlim([0.5, length(levelNames) + 0.5]);
    set(plotHandle, {'Color'}, num2cell(colors, 2));
    box off;
end

end


function [parEst, h, neuronBrainAreas, gam] = getData(models, timePeriods)
parEst = cell(length(models), 1);
pVal = cell(length(models), 1);
gam = cell(length(models), 1);

for timePeriod_ind = 1:length(models),
    [parEst{timePeriod_ind}, gam{timePeriod_ind}, ~, neuronBrainAreas, pVal{timePeriod_ind}] = getCoef(models{timePeriod_ind}, timePeriods{timePeriod_ind}, 'isSim', false);
end

% Adjust for multiple comparisons
p = cellfun(@(x) reshape(x, 1, []), pVal, 'UniformOutput', false);
p = [p{:}];
alpha = 0.05;
sortedP = sort(p(:));
numP = length(p(:));

thresholdLine = ([1:numP]' / numP) * alpha;
threshold_ind = find(sortedP <= thresholdLine, 1, 'last');
threshold = sortedP(threshold_ind);

h = cellfun(@(x) x < threshold, pVal, 'UniformOutput', false);

gam = [gam{:}];
end

