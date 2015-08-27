% Creates a collection of models from the most complicated (all covariates) to
% the least complicated (constant model)

function [modelCollection] = createModelCollection(covariates)

covLength = length(covariates);
modelCollection = [];

for covInd = 1:covLength,
    % All possible unique covariate combinations
    modelInd = nchoosek(1:covLength, covInd);
    if size(modelInd, 2) > 1,
        % Add plus sign between covariates
        modelCollectionCov(:, 1:2:((covInd*2)-1)) = covariates(modelInd);
        emptyCellInd = cellfun(@isempty, modelCollectionCov);
        modelCollectionCov(emptyCellInd) = {' + '};
        modelCollectionCov = num2cell(modelCollectionCov, 1);
        modelCollection = [modelCollection strcat(modelCollectionCov{:})'];
        clear modelCollectionCov;
    else
        modelCollection = [modelCollection covariates(modelInd)];
    end
end

modelCollection = ['Constant', modelCollection];
end