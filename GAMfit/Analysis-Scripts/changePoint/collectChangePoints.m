clear variables; clc;
timePeriod = 'Rule Response';
model = 's(Rule, Trial Time, knotDiff=50) + s(Previous Error History, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50)';
covOfInterest = 'Rule Repetition';
workingDir = getWorkingDir();
% Load Common Parameters
load(sprintf('%s/paramSet.mat', workingDir), ...
    'covInfo', 'timePeriodNames', 'neuronInfo', 'numTotalNeurons');

modelDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
load(sprintf('%s/modelList.mat', modelDir), 'modelList');
changePointDir = sprintf('%s/%s/changePoint/%s', modelDir, modelList(model), covOfInterest);

changePointFiles = dir(sprintf('%s/*_changePoint.mat', changePointDir));
changePointFiles = {changePointFiles.name};
assert(length(changePointFiles) == numTotalNeurons);

changePoints = cell(numTotalNeurons, 1);

for neuron_ind = 1:numTotalNeurons,
    changePoints{neuron_ind} = load(sprintf('%s/%s', changePointDir, changePointFiles{neuron_ind}));
end

changePoints = [changePoints{:}];

timeToSig = cat(2, changePoints.timeToSig);
changeTimes = cat(2, changePoints.changeTimes);
timeToHalfMax = cat(3, changePoints.timeToHalfMax);

neuronName = {changePoints.neuronName};
neuronName = strrep(neuronName, '_', '-');

neuronInfo = values(neuronInfo, neuronName);
neuronInfo = [neuronInfo{:}];

brainArea = {neuronInfo.brainArea};
subject = {neuronInfo.subject};

uniqueSubjects = unique(subject);
uniqueBrainAreas = unique(brainArea);

filter_ind = @(sub, area) ismember(subject, sub) & ismember(brainArea, area);

for sub_ind = 1:length(uniqueSubjects),
    for area_ind = 1:length(uniqueBrainAreas),
        subArea{sub_ind, area_ind} = sprintf('%s - %s', uniqueSubjects{sub_ind}, uniqueBrainAreas{area_ind});
        ind = filter_ind(uniqueSubjects{sub_ind}, uniqueBrainAreas{area_ind});
        meanTimeToSig{sub_ind, area_ind} = nanmean(timeToSig(:, ind), 2);
        meanHalfMax{sub_ind, area_ind} = quantile(nanmean(timeToHalfMax(:, :, ind), 3), [0.025 .5, 0.975], 2);
        curChangeTimes = changeTimes(:, ind);
        deriv = cell(size(curChangeTimes, 1), 1);
        for k = 1:size(curChangeTimes, 1),
            deriv{k} = cat(1, curChangeTimes{k, :});
        end
        allChangeTimes{sub_ind, area_ind} = deriv;
    end
end

numSubArea = numel(allChangeTimes);
%%
figure;
for k = 1:numSubArea,
    subplot(numSubArea,1,k)
    plot(meanHalfMax{1}(:, 2),1:4, '.', 'MarkerSize', 20); hold all;
    line(meanHalfMax{1}(:, [1 3])', repmat([1:4], [2 1]))
    title(subArea{k})
    xlim([-125 750]);
    box off;
end

%% Change Times

figure;
for k = 1:numSubArea,
    subplot(numSubArea,1,k)
    hist(allChangeTimes{k}{1}, 50);
    title(subArea{k})
    xlim([-125 750]);
end

