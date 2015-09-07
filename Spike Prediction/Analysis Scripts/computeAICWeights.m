function [weightsAIC, diffAIC, bestAIC_ind] = computeAICWeights(listAIC)

[bestAIC, bestAIC_ind] = min(listAIC, [], 1);
diffAIC = listAIC - bestAIC;
relativeLikelihood = exp(-0.5 * diffAIC);
weightsAIC = relativeLikelihood ./ sum(relativeLikelihood);

end