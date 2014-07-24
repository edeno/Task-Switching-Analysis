function [X, bsplines, cov_name, covLevel_names, penalty] = factorBySpline(factor, time, varargin)

inParser = inputParser;
inParser.addRequired('factor', @isstruct);
inParser.addRequired('time', @isvector);
inParser.addParamValue('bsplines', [], @isstruct);
inParser.addParamValue('basis_dim', 30, @isnumeric);
inParser.addParamValue('basis_degree', 3, @isnumeric);
inParser.addParamValue('penalty_degree', 2, @isnumeric);
inParser.addParamValue('knots', [], @isvector);

inParser.parse(factor, time, varargin{:});

by = inParser.Results;

dummys = dummyvar(grp2idx(sum(bsxfun(@times, factor.data, 1:size(factor.data, 2)), 2)));
numLevels = size(dummys, 2);

if isempty(by.bsplines)
    [bsplines] = createBSpline(time, 'basis_dim', by.basis_dim, 'basis_degree', by.basis_degree, 'penalty_degree', by.penalty_degree, 'knots', by.knots);
else
    bsplines = by.bsplines;
end

numDim = numLevels * bsplines.basis_dim;
X = zeros(length(time), numDim);
penalty = [zeros(bsplines.basis_dim-1, 1) bsplines.con_penalty];
penalty = [{penalty(:, 2:end)}; squeeze(repmat({penalty}, [1 1 numLevels-1]))];

cov_name = repmat({factor.name}, [1 numDim]);
cov_name = cov_name(:)';
covLevel_names = repmat(factor.levels, [bsplines.basis_dim 1]);
covLevel_names = covLevel_names(:)';

for level_ind = 1:numLevels,
    level_idx = (level_ind-1)*bsplines.basis_dim + [1:bsplines.basis_dim];
    X(:, level_idx) = [dummys(:, level_ind) bsxfun(@times, dummys(:, level_ind), bsplines.con_basis)];
end

X(:, 1) = [];
cov_name(:, 1) = [];
covLevel_names(:, 1) = [];

end