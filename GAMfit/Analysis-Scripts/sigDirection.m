function sigDirection(timePeriods, models)

[parEst, h, neuronBrainAreas, gam] = getData(models, timePeriods);

getBrainArea = @(brainArea) ismember(neuronBrainAreas, brainArea);
meanPosSig = @(brainArea) cellfun(@(sig, est) mean(sig(getBrainArea(brainArea), :, :) & est(getBrainArea(brainArea), :, :)  > 0, 1) * 100, h, parEst, 'UniformOutput', false);
meanNegSig = @(brainArea) cellfun(@(sig, est) mean(sig(getBrainArea(brainArea), :, :) & est(getBrainArea(brainArea), :, :)  < 0, 1) * 100, h, parEst, 'UniformOutput', false);

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

figure;
subplot(1,2,1);
plotMeanSig('ACC');
title('ACC');
subplot(1,2,2);
plotMeanSig('dlPFC');
title('dlPFC');

figure;
s1 = subplot(1,2,1);
plotSigEst('ACC');
title('ACC');

s2 = subplot(1,2,2);
plotSigEst('dlPFC');
title('dlPFC');

[linearLim, linearTicks, ~, percentTicks] = fixLimits([s1, s2], 'expTickInterval', .25);
set([s1, s2], 'YLim', [0, linearLim(end)]);
set([s1, s2], 'YTick', linearTicks);
set([s1, s2], 'YTickLabel', percentTicks);

    function plotMeanSig(brainArea)
        maxLevels = max(cell2mat(arrayfun(@(x) length(x.levelNames), gam, 'UniformOutput', false)));
        fixDim = @(d) cellfun(@(x) [x, nan(1, maxLevels - length(x))] ,d, 'UniformOutput', false);
        meanSig = [cell2mat(fixDim(meanPosSig(brainArea))); cell2mat(fixDim(meanNegSig(brainArea)))]';
        
        b = bar(meanSig(3:end-1, :));
        ylim([0, 30]);
        set(b, {'FaceColor'}, num2cell(colors, 2));
        
        set(gca, 'XTickLabel', gam(end).levelNames(3:end-1));
        box off;
        ylabel('Percent Signficant');
    end

    function plotSigEst(brainArea)
        
        est = [cellfun(@(x) nanmean(x(getBrainArea(brainArea), :)), posEst, 'UniformOutput', false); ...
            cellfun(@(x) nanmean(x(getBrainArea(brainArea), :)), negEst, 'UniformOutput', false)];
        maxLevels = max(cell2mat(arrayfun(@(x) length(x.levelNames), gam, 'UniformOutput', false)));
        
        fixDim = @(d) cellfun(@(x) [x, nan(1, maxLevels - length(x))] ,d, 'UniformOutput', false);
        
        est = cell2mat(fixDim(est))';
        
        plotHandle = plot(abs(est(3:end-1, :)), '.-', 'MarkerSize', 20);
        set(gca, 'XTick', 1:length(gam(end).levelNames(3:end-1)));
        set(gca, 'XTickLabel', gam(end).levelNames(3:end-1));
        xlim([0.5, length(gam(end).levelNames(3:end-1)) + 0.5]);
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

