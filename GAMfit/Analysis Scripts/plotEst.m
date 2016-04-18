function plotEst(parEst, gam, varargin)

inParser = inputParser;
inParser.addRequired('parEst', @isnumeric);
inParser.addRequired('gam', @isstruct);
inParser.addParameter('colors', [0 0 0], @isnumeric);

inParser.parse(parEst, gam, varargin{:});
params = inParser.Results;

bootEst = @(x) squeeze(quantile(nanmedian(x, 1), [0.025, 0.5, 0.975], 3));
numLevels = size(parEst, 2);

ci = bootEst(parEst(:, 2:end, :));

p = plot(exp(ci(:, 2)), (numLevels - 1):-1:1, '.', 'MarkerSize', 20);
set(p, {'Color'}, num2cell(params.colors, 2));
hold all;
l = line(exp(ci(:, [1 3]))', repmat((numLevels - 1):-1:1, [2 1]));
set(l, {'Color'}, num2cell(params.colors, 2));
vline(1);
set(gca, 'YTick', 1:(numLevels - 1));
set(gca, 'YTickLabel', gam.levelNames(numLevels:-1:2));
grid on;
box off;
end