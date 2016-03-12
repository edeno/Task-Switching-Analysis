function newCollectAPCs()
workingDir = getWorkingDir();
timePeriod = 'Rule Response';
modelDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
modelList = load(sprintf('%s/modelList.mat', modelDir));
modelList = modelList.modelList;
model = 'Rule * Previous Error + Response Direction + Rule * Rule Repetition + Congruency';
apcDir = sprintf('%s/%s/APC/', modelDir, modelList(model));
paramSet = load(sprintf('%s/paramSet.mat', workingDir), 'monkeyNames');
monkeyNames = lower(paramSet.monkeyNames);
monkeyNames = monkeyNames(~ismember(monkeyNames, 'ch'));

folderNames = dir(apcDir);
folderNames = {folderNames.name};
folderNames = folderNames(~ismember(folderNames, {'.', '..'}));

for folder_ind = 1:length(folderNames),
    for monkey_ind = 1:length(monkeyNames),
        curMonkey = monkeyNames{monkey_ind};
        fprintf('\nMonkey: %s\n', curMonkey);
        
        fprintf('\nFolder: %s\n', folderNames{folder_ind});
        curFactorDir = sprintf('%s/%s/', apcDir, folderNames{folder_ind});
        APC_files = dir(sprintf('%s/%s*_APC.mat', curFactorDir, curMonkey));
        APC_files = {APC_files.name};
        avpred = [];
        
        for file_ind = 1:length(APC_files),
            fprintf('\t...%s\n', APC_files{file_ind})
            curAPC = load(sprintf('%s/%s', curFactorDir, APC_files{file_ind}));
            avpred = [avpred, curAPC.avpred];
        end
        
        saveDir = sprintf('%s/%s/apcCollected/', apcDir, folderNames{folder_ind});
        if ~exist(saveDir, 'dir'),
            mkdir(saveDir);
        end
        summarizeAPC;
    end
end


    function summarizeAPC
        brainArea = {avpred.brainArea};
        
        uniqueBrainArea = unique(brainArea);
        
        for area_ind = 1:length(uniqueBrainArea),
            curArea = uniqueBrainArea{area_ind};
            fprintf('\nBrain Area: %s\n', curArea);
            
            filter_ind = ismember(brainArea, curArea);
            numNeurons = sum(filter_ind);
            neuronNames = arrayfun(@(x) sprintf('%s-%d-%d', x.sessionName, x.wireNumber, x.unitNumber), avpred(filter_ind), 'uniformOutput', false);
            
            timeLength = max(arrayfun(@(x) length(x.trialTime), avpred(filter_ind)));
            trialTime = min(avpred(1).trialTime):timeLength-abs(min(avpred(1).trialTime))-1;
            
            for neuron_ind = find(filter_ind),
                avpred(neuron_ind).apc = padarray(avpred(neuron_ind).apc, [0, timeLength-length(avpred(neuron_ind).trialTime), 0], NaN, 'post');
                avpred(neuron_ind).abs_apc = padarray(avpred(neuron_ind).abs_apc, [0, timeLength-length(avpred(neuron_ind).trialTime), 0], NaN, 'post');
                avpred(neuron_ind).norm_apc = padarray(avpred(neuron_ind).norm_apc, [0, timeLength-length(avpred(neuron_ind).trialTime), 0], NaN, 'post');
            end
            
            apc = cat(4, avpred(filter_ind).apc);
            abs_apc = cat(4, avpred(filter_ind).abs_apc);
            normSum_apc = cat(4, avpred(filter_ind).norm_apc);
            normSum_abs_apc = abs(cat(4, avpred(filter_ind).norm_apc));
            
            try
                levels = avpred(1).byLevels;
            catch
                levels = avpred(1).comparisonNames;
            end
            numLevels = length(levels);
            
            normBaseline_apc = nan(size(apc));
            normBaseline_abs_apc = nan(size(apc));
            
            baselineFiringRate = squeeze([avpred(filter_ind).baselineFiringRate])';
            
            for level_ind = 1:numLevels,
                for neuron_ind = 1:numNeurons,
                    normBaseline_apc(level_ind, :, :, neuron_ind) = bsxfun(@rdivide, squeeze(apc(level_ind, :, :, neuron_ind)), baselineFiringRate(:, neuron_ind)');
                    normBaseline_abs_apc(level_ind, :, :, neuron_ind) = bsxfun(@rdivide, squeeze(abs_apc(level_ind, :, :, neuron_ind)), baselineFiringRate(:, neuron_ind)');
                end
            end
            
            %% By Neuron
            individualIntervals = @(metric) quantile(metric, [0.025, 0.5, 0.975], 3);
            
            apc_byNeuron = individualIntervals(apc);
            abs_apc_byNeuron = individualIntervals(abs_apc);
            
            normSum_apc_byNeuron = individualIntervals(normSum_apc);
            normSum_abs_apc_byNeuron = individualIntervals(normSum_abs_apc);
            
            normBaseline_abs_apc_byNeuron = individualIntervals(normBaseline_abs_apc);
            normBaseline_apc_byNeuron = individualIntervals(normBaseline_apc);
            
            %% Population
            popIntervals = @(metric) quantile(nanmedian(metric, 4), [0.025, 0.5, 0.975], 3);
            
            apc_pop = popIntervals(apc);
            abs_apc_pop = popIntervals(abs_apc);
            
            normSum_apc_pop = popIntervals(normSum_apc);
            normSum_abs_apc_pop = popIntervals(normSum_abs_apc);
            
            normBaseline_apc_pop = popIntervals(normBaseline_apc);
            normBaseline_abs_apc_pop = popIntervals(normBaseline_abs_apc);
            fprintf('\nSaving...\n');
            save(sprintf('%s/%s_%s_summary.mat', saveDir, curMonkey, curArea), ...
                '*_byNeuron', '*_pop', 'trialTime', 'levels', 'numLevels', 'neuronNames', 'baselineFiringRate');
        end
    end
end