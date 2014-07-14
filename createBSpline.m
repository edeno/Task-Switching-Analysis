function [bsplines] = createBSpline(time, varargin)

inParser = inputParser;
inParser.addRequired('time', @isvector);
inParser.addParamValue('basis_dim', 10, @(x) isnumeric(x) && x >= 0);
inParser.addParamValue('basis_degree', 3, @(x) isnumeric(x) && x >= 0);
inParser.addParamValue('penalty_degree', 2, @(x) isnumeric(x) && x >= 0);
inParser.addParamValue('ridgeLambda', 1E-6, @(x) isnumeric(x) && x >= 0);
inParser.addParamValue('knots', [], @ismatrix);

inParser.parse(time, varargin{:});

bsplines = inParser.Results;

basis_order = bsplines.basis_degree - 1;
basis_rank = bsplines.basis_dim - basis_order;
t = unique(time);

if isempty(bsplines.knots),
    knot_range = diff(quantile(t, [0 1]));
    knot_range = [min(t) - knot_range*0.001 max(t) + knot_range*0.001];
    knots_diff = diff(knot_range)/(basis_rank - 1);
    knots = linspace(knot_range(1) - (knots_diff * bsplines.basis_degree), knot_range(2) + (knots_diff * bsplines.basis_degree), bsplines.basis_dim + (2 * basis_order));
else
    knots = bsplines.knots;
    knots = knots(:);
    knots_diff = diff(bsplines.knots);
    
    if length(knots_diff) == 1,
        knots_diff = knots(2) - knots(1);
        knots = [knots(1) - (knots_diff * ((basis_order+1):-1:1)) knots knots(end) + (knots_diff * (1:(basis_order+1)))];
    else
        bsplines.basis_dim = length(knots);
        knots = [repmat(knots(1), [basis_order+1 1]); knots; repmat(knots(end), [basis_order+1 1])];
    end
    
end

basisMatrix_temp = zeros(length(t), bsplines.basis_dim);

if bsplines.penalty_degree > 0
    sqrtPenMatrix = diff(eye(bsplines.basis_dim), bsplines.penalty_degree);
else
    sqrtPenMatrix = eye(bsplines.basis_dim); % regular ridge regression
end

penaltyMatrix = sqrtPenMatrix'*sqrtPenMatrix;

% Add a small ridge penalty to stablize the regression
ridgePenalty = eye(size(penaltyMatrix)) * bsplines.ridgeLambda;
ridgePenalty(1) = 0;

penaltyMatrix = penaltyMatrix + ridgePenalty;

for cur_basis = 1:bsplines.basis_dim,
    basisMatrix_temp(:, cur_basis) = bspline_basis(t, knots, cur_basis, basis_order);
end

basisMatrix = zeros(length(time), bsplines.basis_dim);

for time_ind = 1:length(t),
    cur_t = t(time_ind);
    basisMatrix(time == cur_t, :) = repmat(basisMatrix_temp(time_ind, :), [sum(time == cur_t) 1]);
end

% C = ones(1, bsplines.basis_dim);
C = nanmean(basisMatrix);
[Q,~] = qr(C');
constraintMatrix = Q(:,2:end);

con_basisMatrix = basisMatrix * constraintMatrix;
con_penaltyMatrix = constraintMatrix' * penaltyMatrix * constraintMatrix;
% con_sqrtPenMatrix = sqrtPenMatrix * constraintMatrix;
con_sqrtPenMatrix = real(sqrtm(con_penaltyMatrix));

bsplines.basis = basisMatrix;
bsplines.sqrtPen = sqrtPenMatrix;
bsplines.penalty = penaltyMatrix;
bsplines.constraint = constraintMatrix;
bsplines.con_basis = con_basisMatrix;
bsplines.con_penalty = con_penaltyMatrix;
bsplines.con_sqrtPen = con_sqrtPenMatrix;
bsplines.knots = knots;
bsplines.knots_diff = knots_diff;
bsplines.x = t;
bsplines.unique_basis = basisMatrix_temp;
bsplines.rank = basis_rank;

end

function [res] = bspline_basis(t, knots, cur_basis, order)
% Recursive Cox-DeBoor formula
% evaluate ith b-spline basis function of order Order at the values in x, given
% knot locations -- knots

if order == -1
    res = (t < knots(cur_basis + 1)) & (t >= knots(cur_basis));
else
    z0 = (t - knots(cur_basis)) / (knots(cur_basis + order + 1) - knots(cur_basis));
    z0(isinf(z0) | isnan(z0)) = 0;
    z1 = (knots(cur_basis + order + 2) - t)/ (knots(cur_basis + order + 2) - knots(cur_basis + 1));
    z1(isinf(z1) | isnan(z1)) = 0;
    res = z0.*bspline_basis(t, knots, cur_basis, order - 1) + z1.*bspline_basis(t, knots, cur_basis + 1, order - 1);
end

end