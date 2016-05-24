function plotEstByBrainArea(modelName, timePeriod, varargin)
inParser = inputParser;
inParser.addRequired('modelName', @ischar);
inParser.addRequired('timePeriod', @ischar);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('colors', [0 0 0], @isnumeric);
inParser.addParameter('onlySig', false, @islogical);

inParser.parse(modelName, timePeriod, varargin{:});
params = inParser.Results;
%% ACC
[parEst, gam] = filterCoef(modelName, timePeriod, 'ACC', params);

s1{1} = subplot(2,2,1);
plotEst(parEst, gam, 'colors', params.colors);
title('Change - ACC');
s2{1} = subplot(2,2,2);
plotEst(abs(parEst), gam, 'colors', params.colors);
title('Abs. Change - ACC');

%%
[parEst, gam] = filterCoef(modelName, timePeriod, 'dlPFC', params);

s1{2} = subplot(2,2,3);
plotEst(parEst, gam, 'colors', params.colors);
title('Change - dlPFC');
s2{2} = subplot(2,2,4);
plotEst(abs(parEst), gam, 'colors', params.colors);
title('Abs. Change - dlPFC');

s1 = [s1{:}];
xlim = [(1 / (max(cellfun(@max, get(s1, {'XLim'}))))) (max(cellfun(@max, get(s1, {'XLim'}))))];
set(s1, {'XLim'}, {xlim})

s2 = [s2{:}];
xlim = [1 max(cellfun(@max, get(s2, {'XLim'})))];
set(s2, {'XLim'}, {xlim})

end

function [parEst, gam, h] = filterCoef(modelName, timePeriods, brainArea, params)
[parEst, gam, ~, ~, ~, h] = getCoef(modelName, timePeriods, 'brainArea', brainArea, 'isSim', true, 'subject', params.subject);

numLevels = length(gam.levelNames);

bad_ind = (exp(parEst(:, 1, :)) * 1000) <  0.5; % exclude neurons with < 0.5 Hz firing rate
bad_ind = repmat(bad_ind, [1, numLevels, 1]);
parEst(bad_ind) = NaN;
if params.onlySig,
    h = repmat(h, [1 1 size(parEst, 3)]);
    parEst(~h) = NaN;
end
end