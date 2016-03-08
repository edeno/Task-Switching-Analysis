function [summed_weights] = apc_weights(other_inputs, isCategorical)

covx = nancov(other_inputs);

% Set categorical covariance to zero, variance to one
covx(isCategorical, :) = 0;
covx(:, isCategorical) = 0;

for cov_ind = find(isCategorical),
    covx(cov_ind, cov_ind) = 1;
end

[numData, numOtherPredictors] = size(other_inputs);
summed_weights = zeros(numData, 1);

parfor cur_data = 1:numData, % Loop through all data points (i)
    
    % Compute the weight matrix based on Mahalanobis distances:
    x_diff = zeros(numOtherPredictors, numData);
    x_diff(~isCategorical, :) = bsxfun(@minus, other_inputs(cur_data, ~isCategorical), other_inputs(:, ~isCategorical))';
    x_diff(isCategorical, :) = double(bsxfun(@ne, other_inputs(cur_data, isCategorical), other_inputs(:, isCategorical))');
    weights = 1 ./ (1 + nansum(x_diff .* (covx \ x_diff)));
    summed_weights(cur_data) = nansum(weights);    
end
end