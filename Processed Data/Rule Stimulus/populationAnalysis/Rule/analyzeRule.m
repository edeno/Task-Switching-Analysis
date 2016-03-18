clear variables;
fileNames = dir('*_permutationAnalysis.mat');
fileNames = {fileNames.name};
avgFiringRate = [];
neuronNames = [];
p = [];
obsDiff = [];

for file_ind = 1:length(fileNames),
    file = load(fileNames{file_ind});
    if file_ind == 1,
        comparisonNames = file.comparisonNames;
    end
    
    avgFiringRate = cat(2, avgFiringRate, file.avgFiringRate);
    neuronNames = cat(1, neuronNames, file.neuronNames);
    obsDiff = cat(2, obsDiff, file.obsDiff);
    p = cat(2, p, file.p);
end

%
neuronBrainArea = [];
monkeyNames = [];
spikeCovDir = 'C:\Users\edeno\Documents\GitHub\Task-Switching-Analysis\Processed Data\Rule Stimulus\SpikeCov';
spikeCovFileNames = dir(sprintf('%s/*_SpikeCov.mat', spikeCovDir));
spikeCovFileNames = {spikeCovFileNames.name};
for file_ind = 1:length(fileNames),
    file = load(spikeCovFileNames{file_ind}, 'neuronBrainArea');
    neuronBrainArea = cat(1, neuronBrainArea, file.neuronBrainArea);
end

isCC = cellfun(@(x) ~isempty(x), strfind(neuronNames, 'cc'));
isISA = cellfun(@(x) ~isempty(x), strfind(neuronNames, 'isa'));
isACC = ismember(neuronBrainArea, 'ACC');
isDLPFC = ismember(neuronBrainArea, 'dlPFC');

%%
alpha = 0.05;
[sortedP, sort_ind] = sort(p);
numP = length(p);

thresholdLine = ([1:numP] / numP) * alpha;
threshold_ind = find(sortedP <= thresholdLine, 1, 'last');
threshold = sortedP(threshold_ind);

h = sortedP <= threshold;
sigObs_ind = ismember(1:numP, sort_ind(h))';

fprintf('\noverall, ACC: %d neurons of %d, %.1f%%\n', sum(isACC & sigObs_ind), sum(isACC), 100 * sum(isACC & sigObs_ind) / sum(isACC));
fprintf('\nmonkey CC, ACC: %d neurons of %d, %.1f%%\n', sum(isACC & isCC & sigObs_ind), sum(isACC & isCC),  100 * sum(isACC & isCC & sigObs_ind) / sum(isACC & isCC));
fprintf('\nmonkey ISA, ACC: %d neurons of %d, %.1f%%\n', sum(isACC & isISA & sigObs_ind), sum(isACC & isISA), 100 * sum(isACC & isISA & sigObs_ind) / sum(isACC & isISA));
fprintf('\n ----------------------\n');
fprintf('\noverall, dlPFC: %d neurons of %d, %.1f%% \n', sum(isDLPFC & sigObs_ind), sum(isDLPFC), 100 * sum(isDLPFC & sigObs_ind) / sum(isDLPFC));
fprintf('\nmonkey CC, dlPFC: %d neurons of %d, %.1f%%\n', sum(isDLPFC & isCC & sigObs_ind), sum(isDLPFC & isCC), 100 * sum(isDLPFC & isCC & sigObs_ind) / sum(isDLPFC & isCC));
fprintf('\nmonkey ISA, dlPFC: %d neurons of %d, %.1f%%\n', sum(isDLPFC & isISA & sigObs_ind), sum(isDLPFC & isISA), 100 * sum(isDLPFC & isISA & sigObs_ind) / sum(isDLPFC & isISA));

%%
normalizationMethod = 'probability';

figure;
s1 = subplot(4,2,1);
histogram(obsDiff(isACC),'Normalization',normalizationMethod);
title('ACC');
xlabel('Raw Firing Rate Difference (Spikes / s)')

s2 = subplot(4,2,2);
histogram(obsDiff(isDLPFC),'Normalization',normalizationMethod);
title('dlPFC')
xlabel('Raw Firing Rate Difference (Spikes / s)')

maxChange = round(max(abs(obsDiff)));
s1.XLim = [-maxChange, maxChange];
s2.XLim = [-maxChange, maxChange];

s3 = subplot(4,2,3);
histogram(obsDiff(isACC) ./ avgFiringRate(isACC),'Normalization',normalizationMethod);
xlabel('Normalized Firing Rate Difference (by Average Firing Rate)')

s4 = subplot(4,2,4);
histogram(obsDiff(isDLPFC) ./ avgFiringRate(isDLPFC),'Normalization',normalizationMethod);
xlabel('Normalized Firing Rate Difference (by Average Firing Rate)')

maxChange = round(max(abs(obsDiff ./ avgFiringRate)));
s3.XLim = [-maxChange, maxChange];
s4.XLim = [-maxChange, maxChange];

s5 = subplot(4,2,5);
histogram(obsDiff(isACC & sigObs_ind),'Normalization',normalizationMethod);
xlabel('Significant Raw Firing Rate Difference (Spikes / s)')

s6 = subplot(4,2,6);
histogram(obsDiff(isDLPFC & sigObs_ind),'Normalization',normalizationMethod);
xlabel('Significant Raw Firing Rate Difference (Spikes / s)')

maxChange = round(max(abs(obsDiff(sigObs_ind))));
s5.XLim = [-maxChange, maxChange];
s6.XLim = [-maxChange, maxChange];

s7 = subplot(4,2,7);
histogram(obsDiff(isACC & sigObs_ind) ./ avgFiringRate(isACC & sigObs_ind),'Normalization',normalizationMethod);
xlabel('Significant Normalized Firing Rate Difference (by Average Firing Rate)')

s8 = subplot(4,2,8);
histogram(obsDiff(isDLPFC & sigObs_ind) ./ avgFiringRate(isDLPFC & sigObs_ind),'Normalization',normalizationMethod);
xlabel('Significant Normalized Firing Rate Difference (by Average Firing Rate)')

maxChange = round(max(abs(obsDiff(sigObs_ind) ./ avgFiringRate(sigObs_ind))));
s7.XLim = [-maxChange, maxChange];
s8.XLim = [-maxChange, maxChange];

suptitle(comparisonNames)