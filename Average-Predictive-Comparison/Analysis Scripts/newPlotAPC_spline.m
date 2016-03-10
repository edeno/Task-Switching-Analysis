brainArea = {avpred.brainArea};
isACC = ismember(brainArea, 'ACC');
isDLPFC = ~isACC;
monkeyNames = {avpred.monkeyNames};
isCC = ismember(monkeyNames, 'cc');
isISA = ismember(monkeyNames, 'isa');

numNeurons = length(avpred);

apc = cat(4, avpred.apc);
abs_apc = cat(4, avpred.abs_apc);
normSum_apc = cat(4, avpred.norm_apc);
normSum_abs_apc = abs(cat(4, avpred.norm_apc));

baselineFiringRate = squeeze([avpred.baselineFiringRate])';

levels = avpred(1).byLevels;
numLevels = length(levels);
trialTime = avpred(1).trialTime;

normBaseline_apc = nan(size(apc));
normBaseline_abs_apc = nan(size(apc));

for level_ind = 1:numLevels,
    for neuron_ind = 1:numNeurons,
        normBaseline_apc(level_ind, :, :, neuron_ind) = bsxfun(@rdivide, squeeze(apc(level_ind, :, :, neuron_ind)), baselineFiringRate(:, neuron_ind)');
        normBaseline_abs_apc(level_ind, :, :, neuron_ind) = bsxfun(@rdivide, squeeze(abs_apc(level_ind, :, :, neuron_ind)), baselineFiringRate(:, neuron_ind)');
    end
end

colors = [ ...
    102,194,165; ...
    252,141,98; ...
    141,160,203; ...
    231,138,195; ...
    166,216,84; ...
    ] ./ 255;
%% By Neuron
abs_apc_byNeuron = quantile(abs_apc, [0.025 0.5 0.975], 3);
apc_byNeuron = quantile(apc, [0.025 0.5 0.975], 3);

normSum_apc_byNeuron = quantile(normSum_apc, [0.025 0.5 0.975], 3);
normSum_abs_apc_byNeuron = quantile(normSum_abs_apc, [0.025 0.5 0.975], 3);

normBaseline_abs_apc_byNeuron = quantile(normBaseline_abs_apc, [0.025 0.5 0.975], 3);
normBaseline_apc_byNeuron = quantile(normBaseline_apc, [0.025 0.5 0.975], 3);

%% Population
curArea = 'ACC';
curMonkey = 'cc';
filter_ind = ismember(monkeyNames, curMonkey) & ismember(brainArea, curArea);
popIntervals = @(metric) quantile(nanmedian(metric(:, :, :, filter_ind), 4), [0.025, 0.5, 0.975], 3);

apc_pop = popIntervals(apc);
abs_apc_pop = popIntervals(abs_apc);

normSum_apc_pop = popIntervals(normSum_apc);
normSum_abs_apc_pop = popIntervals(normSum_abs_apc);

normBaseline_apc_pop = popIntervals(normBaseline_apc);
normBaseline_abs_apc_pop = popIntervals(normBaseline_abs_apc);

figure;
for level_ind = 1:numLevels,
    subplot(3,2,1);
    plot(trialTime, squeeze(apc_pop(level_ind, :, :)), 'Color', colors(level_ind, :)); hold all;
    t = text(trialTime(end) + 1, apc_pop(level_ind, end, 2), levels{level_ind});
    t.Color = colors(level_ind, :);
    title('apc');
    
    subplot(3,2,2);
    plot(trialTime, squeeze(abs_apc_pop(level_ind, :, :)), 'Color', colors(level_ind, :)); hold all;
    t = text(trialTime(end) + 1, abs_apc_pop(level_ind, end, 2), levels{level_ind});
    t.Color = colors(level_ind, :);
    title('abs apc');
    
    subplot(3,2,3);
    plot(trialTime, squeeze(normSum_apc_pop(level_ind, :, :)),'Color', colors(level_ind, :)); hold all;
    t = text(trialTime(end) + 1, normSum_apc_pop(level_ind, end, 2), levels{level_ind});
    t.Color = colors(level_ind, :);
    title('normSum apc');
    
    subplot(3,2,4);
    plot(trialTime, squeeze(normSum_abs_apc_pop(level_ind, :, :)), 'Color', colors(level_ind, :)); hold all;
    t = text(trialTime(end) + 1, normSum_abs_apc_pop(level_ind, end, 2), levels{level_ind});
    t.Color = colors(level_ind, :);
    title('normSum apc');
    
    subplot(3,2,5);
    plot(trialTime, squeeze(normBaseline_apc_pop(level_ind, :, :)), 'Color', colors(level_ind, :)); hold all;
    t = text(trialTime(end) + 1, normBaseline_apc_pop(level_ind, end, 2), levels{level_ind});
    t.Color = colors(level_ind, :);
    title('normBaseline apc');
    
    subplot(3,2,6);
    plot(trialTime, squeeze(normBaseline_abs_apc_pop(level_ind, :, :)), 'Color', colors(level_ind, :)); hold all;
    t = text(trialTime(end) + 1, normBaseline_abs_apc_pop(level_ind, end, 2), levels{level_ind});
    t.Color = colors(level_ind, :);
    title('normBaseline abs apc');
end

