%% Converts a color string to rgb. Handles rgb colors by just returning them.
function [rgbColor] = str2RGBColor(color)
keys = {'y', 'yellow', 'm', 'magenta', 'c', 'cyan', 'r', 'red', 'g', 'green', 'b', 'blue', 'w', 'white', 'k', 'black'};
values = {[1 1 0], [1 1 0], [1 0 1], [1 0 1], [0 1 1], [0 1 1], [1 0 0], [1 0 0], [0 1 0], [0 1 0], [0 0 1], [0 0 1], [1 1 1], [1 1 1], [0 0 0], [0 0 0]};
colorMap = containers.Map(keys, values);
if colorMap.isKey(color),
    rgbColor = colorMap(color);
elseif isnumeric(color)
    rgbColor = color;
else
    warning('Not an existing color');
    rgbColor = NaN;
end
end