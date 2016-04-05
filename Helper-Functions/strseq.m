% Takes a string and an index and turns them into a sequence i.e. blah1,
% blah2, blah3. Overrides function of the same name in the matlab control
% toolbox. Returns a cell array of strings
function [out] = strseq(str, ind)

ind = ind(:); % Ensure index is a vector
out = cellfun(@(x) sprintf('%s%d', str, x), num2cell(ind), 'UniformOutput', false);

end