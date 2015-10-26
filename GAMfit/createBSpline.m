function [bsplines] = createBSpline(time, varargin)

inParser = inputParser;
inParser.addRequired('time', @isvector);
inParser.addParameter('basisDim', 10, @(x) isnumeric(x) && x >= 0);
inParser.addParameter('basisDegree', 3, @(x) isnumeric(x) && x >= 0);
inParser.addParameter('penaltyDegree', 2, @(x) isnumeric(x) && x >= 0);
inParser.addParameter('ridgeLambda', 1E-1, @(x) isnumeric(x) && x >= 0);
inParser.addParameter('knots', [], @ismatrix);

inParser.parse(time, varargin{:});

bsplines = inParser.Results;

basisOrder = bsplines.basisDegree - 1;
basisRank = bsplines.basisDim - basisOrder;
t = unique(time);

if isempty(bsplines.knots),
    knot_range = diff(quantile(t, [0 1]));
    knot_range = [min(t) - (knot_range * 0.001), max(t) + (knot_range * 0.001)];
    knotsDiff = diff(knot_range) / (basisRank - 1);
    knots = linspace(knot_range(1) - (knotsDiff * bsplines.basisDegree), knot_range(2) + (knotsDiff * bsplines.basisDegree), bsplines.basisDim + (2 * basisOrder));
else
    knots = bsplines.knots;
    knots = knots(:);
    knotsDiff = diff(bsplines.knots);
    
    if length(knotsDiff) == 1,
        knotsDiff = knots(2) - knots(1);
        knots = [knots(1) - (knotsDiff * ((basisOrder + 1):-1:1)) knots knots(end) + (knotsDiff * (1:(basisOrder+1)))];
    else
        bsplines.basisDim = length(knots);
        knots = [repmat(knots(1), [basisOrder + 1, 1]); knots; repmat(knots(end), [basisOrder + 1, 1])];
    end
    
end

basisMatrix_temp = zeros(length(t), bsplines.basisDim);

if bsplines.penaltyDegree > 0
    sqrtPenMatrix = diff(eye(bsplines.basisDim), bsplines.penaltyDegree);
else
    sqrtPenMatrix = eye(bsplines.basisDim); % regular ridge regression
end

penaltyMatrix = sqrtPenMatrix'*sqrtPenMatrix;

% Add a small ridge penalty to stablize the regression
ridgePenalty = eye(size(penaltyMatrix)) * bsplines.ridgeLambda;
ridgePenalty(1) = 0;

penaltyMatrix = penaltyMatrix + ridgePenalty;

for cur_basis = 1:bsplines.basisDim,
    basisMatrix_temp(:, cur_basis) = bSplineBasis(t, knots, cur_basis, basisOrder);
end

basisMatrix = zeros(length(time), bsplines.basisDim);

for time_ind = 1:length(t),
    cur_t = t(time_ind);
    basisMatrix(time == cur_t, :) = repmat(basisMatrix_temp(time_ind, :), [sum(time == cur_t) 1]);
end

% C = ones(1, bsplines.basisDim);
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
bsplines.knotsDiff = knotsDiff;
bsplines.x = t;
bsplines.unique_basis = basisMatrix_temp;
bsplines.rank = basisRank;

end

function [res] = bSplineBasis(t, knots, cur_basis, order)
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
    res = z0 .* bSplineBasis(t, knots, cur_basis, order - 1) + z1 .* bSplineBasis(t, knots, cur_basis + 1, order - 1);
end

end