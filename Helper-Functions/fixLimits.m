function [linearLim, linearTicks, expTicks, percentTicks] = fixLimits(axesArray, varargin)

inParser = inputParser;
inParser.addRequired('axesArray', @isobject);
inParser.addParameter('expTickInterval', 0.05, @isnumeric);
inParser.addParameter('isSimple', false, @islogical);
inParser.parse(axesArray, varargin{:});
params = inParser.Results;

linearLim = get(axesArray, 'YLim'); % Get Limits
if iscell(linearLim),
    linearLim = quantile([linearLim{:}], [0 1]); % Find max-min
else
    linearLim = quantile(linearLim, [0 1]); % Find max-min
end

expLim(1) = floor(exp(linearLim(1)) * 10) / 10; % round to nearest tenth in exponential space
expLim(2) = ceil(exp(linearLim(end)) * 10) / 10; % round to nearest tenth in exponential space

if ~params.isSimple,
    expTicks = expLim(1):params.expTickInterval:expLim(2);
else
    expTicks = unique([expLim(1), 1, expLim(2)]);
end

percentTicks = (expTicks - 1) * 100;

linearLim = log(expLim);
linearTicks = log(expTicks);

end