function [diffCI, h, levelNames, covNames] = compareDemandByBrainAreas(modelName, timePeriods, varargin)
inParser = inputParser;
inParser.addRequired('modelName', @iscell);
inParser.addRequired('timePeriods', @iscell);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('numSim', 1E4, @isnumeric);

inParser.parse(modelName, timePeriods, varargin{:});
params = inParser.Results;

brainAreas = {'ACC', 'dlPFC'};

numTimePeriods = length(timePeriods);
numBrainAreas = length(brainAreas);
parEst = cell(numTimePeriods, numBrainAreas);

for area_ind = 1:numBrainAreas,
    
    gam = cell(size(timePeriods));
    for time_ind = 1:numTimePeriods,
        [est, gam{time_ind}] = filterCoef(modelName{time_ind}, timePeriods{time_ind}, brainAreas{area_ind}, params);
        parEst{time_ind, area_ind} = squeeze(nanmean(est(:, 2:end, :)));
    end
    
end

gam = [gam{:}];
levelLength = arrayfun(@(x) length(x.levelNames(2:end)), gam, 'UniformOutput', false);
levelLength = [levelLength{:}];
[maxLevelLength, max_ind] = max(levelLength);
levelNames = gam(max_ind).levelNames(2:end);
covNames = gam(max_ind).covNames(2:end);

diffCI = nan(maxLevelLength, 3, numTimePeriods);
for time_ind = 1:numTimePeriods,
    level_ind = ismember(levelNames, gam(time_ind).levelNames);
    diffCI(level_ind, :, time_ind) = quantile(parEst{time_ind, 1} - parEst{time_ind, 2}, [0.025, .5, 0.975], 2);
end

h = diffCI(:, 1, :) > 0 | diffCI(:, 3, :) < 0;

%%

end

%%
function [parEst, gam] = filterCoef(modelName, timePeriods, brainArea, params)
[parEst, gam] = getCoef(modelName, timePeriods, 'brainArea', brainArea, 'isSim', true, 'subject', params.subject, 'numSim', params.numSim);

bad_ind = abs(parEst) > 10;
bad_ind(:, 1, :) = false;

parEst(bad_ind) = NaN;
end