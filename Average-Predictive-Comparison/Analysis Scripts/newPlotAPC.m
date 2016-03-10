brainArea = {avpred.brainArea};
isACC = ismember(brainArea, 'ACC');
isDLPFC = ~isACC;

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
abs_apc_byNeuron = quantile(abs_apc, [0.025 0.5 0.975], 2);
apc_byNeuron = quantile(apc, [0.025 0.5 0.975], 2);

normSum_apc_byNeuron = quantile(normSum_apc, [0.025 0.5 0.975], 2);
normSum_abs_apc_byNeuron = quantile(normSum_abs_apc, [0.025 0.5 0.975], 2);

normBaseline_abs_apc_byNeuron = quantile(normBaseline_abs_apc, [0.025 0.5 0.975], 2);
normBaseline_apc_byNeuron = quantile(normBaseline_apc, [0.025 0.5 0.975], 2);

%% Population
% ACC
abs_apc_ACC = quantile(nanmedian(abs_apc(:, :, isACC), 3), [0.025, 0.05, 0.975], 2);
apc_ACC = quantile(nanmedian(apc(:, :, isACC), 3), [0.025 0.5 0.975], 2);

normSum_apc_ACC = quantile(nanmedian(normSum_apc(:, :, isACC), 3), [0.025 0.5 0.975], 2);
normSum_abs_apc_ACC = quantile(nanmedian(normSum_abs_apc(:, :, isACC), 3), [0.025 0.5 0.975], 2);

normBaseline_abs_apc_ACC = quantile(nanmedian(normBaseline_abs_apc(:, :, isACC), 3), [0.025 0.5 0.975], 2);
normBaseline_apc_ACC = quantile(nanmedian(normBaseline_apc(:, :, isACC), 3), [0.025 0.5 0.975], 2);

% DLPFC
abs_apc_DLPFC = quantile(nanmedian(abs_apc(:, :, isDLPFC), 3), [0.025, 0.05, 0.975], 2);
apc_DLPFC = quantile(nanmedian(apc(:, :, isDLPFC), 3), [0.025 0.5 0.975], 2);

normSum_apc_DLPFC = quantile(nanmedian(normSum_apc(:, :, isDLPFC), 3), [0.025 0.5 0.975], 2);
normSum_abs_apc_DLPFC = quantile(nanmedian(normSum_abs_apc(:, :, isDLPFC), 3), [0.025 0.5 0.975], 2);

normBaseline_abs_apc_DLPFC = quantile(nanmedian(normBaseline_abs_apc(:, :, isDLPFC), 3), [0.025 0.5 0.975], 2);
normBaseline_apc_DLPFC = quantile(nanmedian(normBaseline_apc(:, :, isDLPFC), 3), [0.025 0.5 0.975], 2);

%% Plot ACC
figure;
subplot(3,2,1);
plot(apc_ACC, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('ACC apc');

subplot(3,2,2);
plot(abs_apc_ACC, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('ACC abs apc');

subplot(3,2,3);
plot(normSum_apc_ACC, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('ACC normSum apc');

subplot(3,2,4);
plot(normSum_abs_apc_ACC, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('ACC normSum apc');

subplot(3,2,5);
plot(normBaseline_apc_ACC, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('ACC normBaseline apc');

subplot(3,2,6);
plot(normBaseline_abs_apc_ACC, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('ACC normBaseline abs apc');

%% Plot dlPFC
figure;
subplot(3,2,1);
plot(apc_DLPFC, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('dlPFC apc');

subplot(3,2,2);
plot(abs_apc_DLPFC, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('dlPFC abs apc');

subplot(3,2,3);
plot(normSum_apc_DLPFC, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('dlPFC normSum apc');

subplot(3,2,4);
plot(normSum_abs_apc_DLPFC, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('dlPFC normSum apc');

subplot(3,2,5);
plot(normBaseline_apc_DLPFC, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('dlPFC normBaseline apc');

subplot(3,2,6);
plot(normBaseline_abs_apc_DLPFC, 1:numLevels, 'k');
ax = gca;
ax.YTick = 1:numLevels;
ax.YTickLabel = levels;
title('dlPFC normBaseline abs apc');

%%

