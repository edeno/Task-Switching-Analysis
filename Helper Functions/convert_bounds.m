% Converts actual position of error bars to distance from mean in order to
% play nicely with functions such as error bars or boundedline

function [err] = convert_bounds(y, err)

if size(err, 1) ~= size(y, 1),
    y = y';
end
for line_ind = 1:size(y, 2),
    err(:, :, line_ind) = abs(bsxfun(@minus, y(:, line_ind), err(:, :, line_ind)));
end

end