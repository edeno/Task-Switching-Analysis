function [basis_matrix] = spline_basis(t, knots)
% Cardinal Splines
knots = knots(:);
t = t(:);
t_size = length(t);

knots_diff = diff(knots);
s = 0.5;

basis = [-s  2-s  s-2    s; ...
         2*s s-3  3-2*s -s; ...
         -s  0    s      0; ...
         0   1    0      0];

[~,whichBin] = histc(t, knots);
bad_ind = (whichBin == 0);

t(bad_ind) = [];
whichBin(bad_ind) = [];

u = (t - knots(whichBin))./ knots_diff(whichBin);
u = [u.^3 u.^2 u ones(size(u))];    
basisFun = u * basis;

basis_matrix = zeros(length(t), length(knots));

for bin_ind = 1:max(whichBin),
   basis_matrix(whichBin == bin_ind, bin_ind + [1:4]) = basisFun(whichBin == bin_ind, :);
end

basis_matrix(:, sum(basis_matrix == 0) == size(basis_matrix, 1)) = [];

basis_matrix_temp = nan(t_size, size(basis_matrix, 2));
basis_matrix_temp(~bad_ind, :) = basis_matrix;
basis_matrix = basis_matrix_temp;

end