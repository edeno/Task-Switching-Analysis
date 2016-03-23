clear variables;
workingDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', workingDir), 'numTotalNeurons', 'sessionNames');
timePeriods = {'Rule Stimulus', 'Stimulus Response'};
permAnalysis = containers.Map;

for time_ind = 1:length(timePeriods),
    
    permutationAnalysisDir = sprintf('%s/Processed Data/%s/permutationAnalysis', workingDir, timePeriods{time_ind});
    factors = dir(permutationAnalysisDir );
    factors = {factors.name};
    factors = factors(~ismember(factors, {'.', '..'}));
    
    
    for factor_ind = 1:length(factors),
        fileNames = dir(sprintf('%s/%s/*_permutationAnalysis.mat', permutationAnalysisDir, factors{factor_ind}));
        fileNames = {fileNames.name};
        if length(fileNames) < length(sessionNames),
            continue;
        end
        for file_ind = 1:length(fileNames),
            file = load(sprintf('%s/%s/%s', permutationAnalysisDir, factors{factor_ind}, fileNames{file_ind}));
            for neuron_ind = 1:length(file.neuronNames)
                curNeuron = file.neuronNames{neuron_ind};
                if ~permAnalysis.isKey(curNeuron),
                    s = [];
                    s.obsDiff = file.obsDiff(:, neuron_ind);
                    s.normObsDiff = file.obsDiff(:, neuron_ind) / file.avgFiringRate(neuron_ind);
                    s.avgFiringRate = file.avgFiringRate(neuron_ind);
                    s.p = file.p(neuron_ind);
                    s.comparisonNames = file.comparisonNames;
                    s.timePeriod = repmat(timePeriods(time_ind), [length(file.obsDiff(:, neuron_ind)), 1]);
                    s.brainArea = file.neuronBrainArea{neuron_ind};
                    s.monkeyName = file.monkeyName;
                    permAnalysis(curNeuron) = s;
                else
                    s = permAnalysis(curNeuron);
                    s.obsDiff = [s.obsDiff; file.obsDiff(:, neuron_ind)];
                    s.normObsDiff = [s.normObsDiff; file.obsDiff(:, neuron_ind) / file.avgFiringRate(neuron_ind)];
                    s.p = [s.p; file.p(:, neuron_ind)];
                    s.comparisonNames = [s.comparisonNames; file.comparisonNames];
                    s.timePeriod = [s.timePeriod; repmat(timePeriods(time_ind), [length(file.obsDiff(:, neuron_ind)), 1])];
                    permAnalysis(curNeuron) = s;
                end
            end
        end
    end
end

neuronNames = permAnalysis.keys;

%% Adjust for multiple comparisons
values = permAnalysis.values;
values = [values{:}];
p = cat(1, values.p);
alpha = 0.05;
[sortedP, sort_ind] = sort(p);
numP = length(p);

thresholdLine = ([1:numP]' / numP) * alpha;
threshold_ind = find(sortedP <= thresholdLine, 1, 'last');
threshold = sortedP(threshold_ind);
figure; plot(sortedP); hold all; plot(thresholdLine, 'k'); vline(threshold_ind, 'Label', 'P-value Threshold');
xlabel('Sorted P-Values');

h = p < threshold;

h = reshape(h, length(values(1).comparisonNames), numTotalNeurons);

for neuron_ind = 1:length(neuronNames),
    curNeuron = neuronNames{neuron_ind};
    s = permAnalysis(curNeuron);
    s.h = h(:, neuron_ind);
    permAnalysis(curNeuron) = s;
end

values = permAnalysis.values;
values = [values{:}];

comparisonNames = values(1).comparisonNames;

saveName = sprintf('%s/Permutation-Analysis/Analysis/colllectedPermAnalysis.mat', workingDir);
save(saveName);