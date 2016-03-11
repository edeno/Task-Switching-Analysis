function summarizeAPC(avpred, collectedDir)
brainArea = {avpred.brainArea};
monkeyNames = {avpred.monkeyNames};

uniqueBrainArea = unique(brainArea);
uniqueMonkeyNames = unique(monkeyNames);

timeLength = max(arrayfun(@(x) length(x.trialTime), avpred));
numNeurons = length(avpred);

for neuron_ind = 1:numNeurons,
    avpred(neuron_ind).apc = padarray(avpred(neuron_ind).apc, [0, timeLength-length(avpred(neuron_ind).trialTime), 0], NaN, 'post');
    avpred(neuron_ind).abs_apc = padarray(avpred(neuron_ind).abs_apc, [0, timeLength-length(avpred(neuron_ind).trialTime), 0], NaN, 'post');
    avpred(neuron_ind).norm_apc = padarray(avpred(neuron_ind).norm_apc, [0, timeLength-length(avpred(neuron_ind).trialTime), 0], NaN, 'post');
end

apc = cat(4, avpred.apc);
abs_apc = cat(4, avpred.abs_apc);
normSum_apc = cat(4, avpred.norm_apc);
normSum_abs_apc = abs(cat(4, avpred.norm_apc));

baselineFiringRate = squeeze([avpred.baselineFiringRate])';

try
    levels = avpred(1).byLevels;
catch
    levels = avpred(1).comparisonNames;
end
numLevels = length(levels);

normBaseline_apc = nan(size(apc));
normBaseline_abs_apc = nan(size(apc));

for level_ind = 1:numLevels,
    for neuron_ind = 1:numNeurons,
        normBaseline_apc(level_ind, :, :, neuron_ind) = bsxfun(@rdivide, squeeze(apc(level_ind, :, :, neuron_ind)), baselineFiringRate(:, neuron_ind)');
        normBaseline_abs_apc(level_ind, :, :, neuron_ind) = bsxfun(@rdivide, squeeze(abs_apc(level_ind, :, :, neuron_ind)), baselineFiringRate(:, neuron_ind)');
    end
end

for monkey_ind = 1:length(uniqueMonkeyNames),
    curMonkey = uniqueMonkeyNames{monkey_ind};
    fprintf('\nMonkey: %s\n', curMonkey);
    for area_ind = 1:length(uniqueBrainArea),
        curArea = uniqueBrainArea{area_ind};
        fprintf('\nBrain Area: %s\n', curArea);
        
        filter_ind = ismember(monkeyNames, curMonkey) & ismember(brainArea, curArea);
        %% By Neuron
        individualIntervals = @(metric) quantile(metric, [0.025, 0.5, 0.975], 3);
        
        apc_byNeuron = individualIntervals(apc(:, :, :, filter_ind));
        abs_apc_byNeuron = individualIntervals(abs_apc(:, :, :, filter_ind));
        
        normSum_apc_byNeuron = individualIntervals(normSum_apc(:, :, :, filter_ind));
        normSum_abs_apc_byNeuron = individualIntervals(normSum_abs_apc(:, :, :, filter_ind));
        
        normBaseline_abs_apc_byNeuron = individualIntervals(normBaseline_abs_apc(:, :, :, filter_ind));
        normBaseline_apc_byNeuron = individualIntervals(normBaseline_apc(:, :, :, filter_ind));
        
        %% Population
        trialTime = min(avpred(find(filter_ind, 1)).trialTime):943-abs(min(avpred(find(filter_ind, 1)).trialTime))-1;
        popIntervals = @(metric) squeeze(quantile(nanmedian(metric(:, :, :, filter_ind), 4), [0.025, 0.5, 0.975], 3));
        
        apc_pop = popIntervals(apc);
        abs_apc_pop = popIntervals(abs_apc);
        
        normSum_apc_pop = popIntervals(normSum_apc);
        normSum_abs_apc_pop = popIntervals(normSum_abs_apc);
        
        normBaseline_apc_pop = popIntervals(normBaseline_apc);
        normBaseline_abs_apc_pop = popIntervals(normBaseline_abs_apc);
        fprintf('\nSaving...\n');
        save(sprintf('%s/%s_%s_summary.mat', collectedDir, curMonkey, curArea), '*_byNeuron', '*_pop', 'trialTime', 'levels');
    end
end
end