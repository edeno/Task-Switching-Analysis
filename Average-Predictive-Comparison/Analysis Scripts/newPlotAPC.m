brainArea = {avpred.brainArea};
isACC = ismember(brainArea, 'ACC');
isDLPFC = ~isACC;
monkeyNames = {avpred.monkeyNames};
isCC = ismember(monkeyNames, 'cc');
isISA = ismember(monkeyNames, 'isa');

apc = cat(4, avpred.apc);
apc = squeeze(apc(:, 1, :, :));

abs_apc = cat(4, avpred.abs_apc);
abs_apc = squeeze(abs_apc(:, 1, :, :));

normSum_apc = cat(4, avpred.norm_apc);
normSum_apc = squeeze(normSum_apc(:, 1, :, :));

normSum_abs_apc = abs(cat(4, avpred.norm_apc));
normSum_abs_apc = squeeze(normSum_abs_apc(:, 1, :, :));

baselineFiringRate = squeeze([avpred.baselineFiringRate])';

levels = avpred(1).byLevels;
numLevels = length(levels);

normBaseline_apc = nan(size(apc));
normBaseline_abs_apc = nan(size(apc));

for level_ind = 1:numLevels,
    normBaseline_apc(level_ind, :, :) = squeeze(apc(level_ind, :, :)) ./ baselineFiringRate;
    normBaseline_abs_apc(level_ind, :, :) = squeeze(abs_apc(level_ind, :, :)) ./ baselineFiringRate;
end

%% By Neuron
individualIntervals = @(metric) quantile(metric, [0.025, 0.5, 0.975], 2);

apc_byNeuron = individualIntervals(apc);
abs_apc_byNeuron = individualIntervals(abs_apc);

normSum_apc_byNeuron = individualIntervals(normSum_apc);
normSum_abs_apc_byNeuron = individualIntervals(normSum_abs_apc);

normBaseline_abs_apc_byNeuron = individualIntervals(normBaseline_abs_apc);
normBaseline_apc_byNeuron = individualIntervals(normBaseline_apc);

%% Population
curArea = 'ACC';
curMonkey = 'cc';
filter_ind = ismember(monkeyNames, curMonkey) & ismember(brainArea, curArea);
popIntervals = @(metric) quantile(nanmedian(metric(:, :, filter_ind), 3), [0.025, 0.5, 0.975], 2);

apc_pop = popIntervals(apc);
abs_apc_pop = popIntervals(abs_apc);

normSum_apc_pop = popIntervals(normSum_apc);
normSum_abs_apc_pop = popIntervals(normSum_abs_apc);

normBaseline_apc_pop = popIntervals(normBaseline_apc);
normBaseline_abs_apc_pop = popIntervals(normBaseline_abs_apc);

figure;
subplot(3,2,1);
plot(apc_pop, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('apc');

subplot(3,2,2);
plot(abs_apc_pop, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('abs apc');

subplot(3,2,3);
plot(normSum_apc_pop, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('normSum apc');

subplot(3,2,4);
plot(normSum_abs_apc_pop, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('normSum apc');

subplot(3,2,5);
plot(normBaseline_apc_pop, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('normBaseline apc');

subplot(3,2,6);
plot(normBaseline_abs_apc_pop, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('normBaseline abs apc');
