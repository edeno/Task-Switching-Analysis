function [weightsAIC, diffAIC, bestAIC_ind] = computeAICWeights(listAIC, dim)
% dim corresponds to dimension containing models
[bestAIC, bestAIC_ind] = min(listAIC, [], dim);
diffAIC = bsxfun(@minus, listAIC, bestAIC);
relativeLikelihood = exp(-0.5 * diffAIC);
weightsAIC = bsxfun(@rdivide, relativeLikelihood,  nansum(relativeLikelihood, dim));
end