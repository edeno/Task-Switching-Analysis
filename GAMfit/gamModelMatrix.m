function [designMatrix, gam] = gamModelMatrix(model_str, GLMCov, response, varargin)

inParser = inputParser;
inParser.addRequired('model_str', @ischar);
inParser.addRequired('GLMCov', @isstruct);
inParser.addRequired('response', @isvector);

inParser.parse(model_str, GLMCov, response, varargin{:});

gam = inParser.Results;
gam = rmfield(gam, {'GLMCov', 'response'});

[model] = modelFormula_parse(gam.model_str);

% Now create the design matrix

designMatrix_constant = ones(size(response));
designMatrix_spline = [];

cov_names_constant = {'(Intercept)'};
sqrtPen_constant = {0};
constraints_constant = {1};
constraintLevel_constant = {'(Intercept)'};
penalty_constant = {0};

cov_names_spline = [];
sqrtPen_spline = [];
constraints_spline = [];
constraintLevel_spline = [];
penalty_spline = [];
levels_spline = [];

numTerms = length(model.terms);

bsplines = cell(numTerms, 1);

% For each term
for curTerm = 1:numTerms,
    
    term_names = regexp(model.terms{curTerm}, ':', 'split');
    data_ind = find(ismember({GLMCov.name}, term_names));
    
    data = {GLMCov(data_ind).data};
    levels = {GLMCov(data_ind).levels};
    
    % Convert to indicator variables if categorical
    isCategorical = [GLMCov(data_ind).isCategorical];
    data = indicatorVar(data, isCategorical, levels, 'Full');
    numLevels = cellfun(@(x) 1:length(x), levels, 'UniformOutput', false);
    
    % Figure out all the relevant interactions
    if length(numLevels) < 2,
        % If no interactions, then just let the factor be added to the
        % design matrix
        data_temp = data{:};
        levels_temp = levels{:};
    else
        % Find all combinations of levels of each factor  
        [rep] = allpairs2(numLevels);
        
        % Sort so that the interactions start with the first level of the
        % first factor, then the second, and so on.
        [~, rep_sort_ind] = sort(rep{1});
        for rep_ind = 1:length(rep),
            rep{rep_ind} = rep{rep_ind}(rep_sort_ind);
        end
        
        % Replicate each factor level the number of times needed for all
        % possible combintations
        data = cellfun(@(data, rep) data(:, rep), data, rep, 'UniformOutput', false);
        levels = cellfun(@(levels, rep) levels(:, rep), levels, rep, 'UniformOutput', false);
        
        % Multiply the factors together for the interactions
        data_temp = data{1};
        levels_temp = levels{1};
        
        for var_ind = 2:length(data),
            data_temp = data_temp.*data{var_ind};
            levels_temp = strcat(levels_temp, ':', levels{var_ind});
        end
        
    end
    
    designMatrix_constant = [designMatrix_constant data_temp];
    
    numLevels = size(data_temp, 2);
    
    cov_names_constant = [cov_names_constant repmat(model.terms(curTerm), 1, numLevels)];
    sqrtPen_constant = [sqrtPen_constant repmat({1}, 1, numLevels)];
    constraints_constant = [constraints_constant repmat({1}, 1, numLevels)];
    constraintLevel_constant = [constraintLevel_constant levels_temp];
    penalty_constant = [penalty_constant repmat({1}, 1, numLevels)];
    
    % Deal with Smoothing
    if model.isSmooth(curTerm),
        
        smoothParams = [];
        
        % Factor to be smoothed
        factor.name = model.terms(curTerm);
        factor.data = data_temp;
        factor.levels = levels_temp;
        smoothParams{1} = factor;
        
        % Find smoothing factor
        if isempty(model.smoothingTerm{curTerm}),
            smoothingFactor.data = [];
            smoothingFactor.name = [];
            smoothParams{2} = smoothingFactor;
        else
            smoothingFactor.data = GLMCov(ismember({GLMCov.name}, model.smoothingTerm{curTerm})).data;
            smoothingFactor.name = model.smoothingTerm{curTerm};
            smoothParams{2} = smoothingFactor;
        end
        
        smoothParams = [smoothParams [model.smoothParams_opt{curTerm, :}]];
        
        [smoothMatrix, bsplines{curTerm}, smoothCov_name, smoothLevel_names, ...
            smoothSqrtPen, smoothConstraints, smoothPenalty, smoothConNames] = factorBySpline(smoothParams{:});
        
        designMatrix_spline = [designMatrix_spline smoothMatrix];
        levels_spline = [levels_spline smoothLevel_names];
        cov_names_spline = [cov_names_spline smoothCov_name];
        sqrtPen_spline = [sqrtPen_spline smoothSqrtPen];
        constraints_spline = [constraints_spline smoothConstraints];
        penalty_spline = [penalty_spline smoothPenalty];
        constraintLevel_spline = [constraintLevel_spline smoothConNames];
    end
    
end

designMatrix = [designMatrix_constant designMatrix_spline];
level_names = [constraintLevel_constant levels_spline];
cov_names = [cov_names_constant cov_names_spline];
constraintLevel_names = [constraintLevel_constant constraintLevel_spline];
constraints = [constraints_constant constraints_spline];
sqrtPen = [sqrtPen_constant sqrtPen_spline];
penalty = [penalty_constant penalty_spline];
constant_ind = [true(size(constraintLevel_constant)) false(size(levels_spline))];

% Convert to matrix
sqrtPen = blkdiag(sqrtPen{:});
penalty = blkdiag(penalty{:});
constraints = blkdiag(constraints{:});

% Remove Duplicates
try
    [~, dup_ind] = unique(level_names, 'stable');
    [~, dup_constraint_ind] = unique(constraintLevel_names, 'stable');
catch
    % Matlab versions < 2014a
    [~, dup_ind] = unique(level_names);
    dup_ind = sort(dup_ind);
    [~, dup_constraint_ind] = unique(constraintLevel_names);
    dup_constraint_ind = sort(dup_constraint_ind);
end

designMatrix = designMatrix(:, dup_ind);
level_names = level_names(:, dup_ind);
cov_names = cov_names(:, dup_ind);
sqrtPen = sqrtPen(dup_ind, dup_ind);
penalty = penalty(dup_ind, dup_ind);
constraints = constraints(:, dup_ind);
constant_ind = constant_ind(:, dup_ind);

constraints = constraints(dup_constraint_ind, :);
constraintLevel_names = constraintLevel_names(:, dup_constraint_ind);

level_names = regexprep(level_names, '^(:)|^(::)|(:)$|(::)$', '');
level_names = regexprep(level_names, '::', ':');

gam.cov_names = cov_names;
gam.level_names = level_names;
gam.constraints = constraints;
gam.constraintLevel_names = constraintLevel_names';
gam.penalty = penalty;
gam.sqrtPen = sqrtPen;
gam.bsplines = bsplines;
gam.constant_ind = logical(constant_ind);


end

%-----------------------------------------------------------------------------
function [rep] = allpairs2(C)

[rep{1:length(C)}] = ndgrid(C{:});
rep = cellfun(@(x) x(:)', rep, 'UniformOutput', false);

end

%-----------------------------------------------------------------------------
function [dummy] = indicatorVar(data, isCategorical, levels, type)

dummy = cell(size(data));

switch(type)
    case 'Full' % symmetric coding, no reference level
        dummy(isCategorical) = cellfun(@(dat, level) createIndicator(dat, level), data(isCategorical), levels(isCategorical), 'UniformOutput', false);
        dummy(~isCategorical) = data(~isCategorical);
    case 'Reference' % first level is the reference
        dummy(isCategorical) = cellfun(@(dat, level) createIndicator(dat, level), data(isCategorical), levels(isCategorical), 'UniformOutput', false);
        dummy(~isCategorical) = data(~isCategorical);
end

end
%-----------------------------------------------------------------------------
function [X, bsplines, cov_name, covLevel_names, sqrtPen, constraints, penalty, constraintLevel_names] = factorBySpline(factor, varargin)

inParser = inputParser;
inParser.addRequired('factor', @isstruct);
inParser.addRequired('smoothingFactor', @isstruct);
inParser.addParamValue('bsplines', [], @isstruct);
inParser.addParamValue('basis_dim', 30, @isnumeric);
inParser.addParamValue('basis_degree', 3, @isnumeric);
inParser.addParamValue('penalty_degree', 2, @isnumeric);
inParser.addParamValue('ridgeLambda', 1E-6, @(x) isnumeric(x) && x >= 0);
inParser.addParamValue('knots', [], @isvector);

inParser.parse(factor, varargin{:});

by = inParser.Results;

if isempty(factor.data)
    data = {ones(size(by.smoothingFactor.data))};
    levels = {{''}};
else
    data = [ones(size(by.smoothingFactor.data)) by.factor.data];
    levels = [{by.smoothingFactor.name} by.factor.levels];
end

numLevels = size(data, 2);

if isempty(by.bsplines)
    [bsplines] = createBSpline(by.smoothingFactor.data, 'basis_dim', by.basis_dim, ...
        'basis_degree', by.basis_degree, 'penalty_degree', by.penalty_degree, ...
        'knots', by.knots, 'ridgeLambda', by.ridgeLambda);
else
    bsplines = by.bsplines;
end

numDim = numLevels * (bsplines.basis_dim - 1);
X = zeros(length(by.smoothingFactor.data), numDim);

sqrtPen = [{bsplines.con_sqrtPen} repmat({bsplines.con_sqrtPen}, [1 numLevels-1])];
penalty = [{bsplines.con_penalty} repmat({bsplines.con_penalty}, [1 numLevels-1])];

constraints = [{bsplines.constraint} repmat({bsplines.constraint}, [1 numLevels-1])];

cov_name = repmat({factor.name}, [1 numDim]);
cov_name = cov_name(:)';

covLevel_names = repmat(levels, [bsplines.basis_dim-1 1]);
covLevel_names = covLevel_names(:)';
covLevel_names = strcat(covLevel_names, ['.' by.smoothingFactor.name]);
level_no = num2cell(repmat(1:bsplines.basis_dim-1, [1 numLevels]));
level_no = cellfun(@(x) num2str(x), level_no, 'UniformOutput', false);
covLevel_names = strcat(covLevel_names, '.', level_no);

constraintLevel_names = repmat(levels, [bsplines.basis_dim 1]);
constraintLevel_names = constraintLevel_names(:)';
constraintLevel_names = strcat(constraintLevel_names, ['.' by.smoothingFactor.name]);
level_no = num2cell(repmat(1:bsplines.basis_dim, [1 numLevels]));
level_no = cellfun(@(x) num2str(x), level_no, 'UniformOutput', false);
constraintLevel_names = strcat(constraintLevel_names, '.', level_no);

for level_ind = 1:numLevels,
    level_idx = (level_ind-1)*(bsplines.basis_dim-1) + [1:bsplines.basis_dim-1];
    X(:, level_idx) = [bsxfun(@times, data(:, level_ind), bsplines.con_basis)];
end


end
%-----------------------------------------------------------------------------
function [out] = createIndicator(data, levels)

numDataLevels = 0;
for col_ind = 1:size(data, 2),
    numUnique = unique(data(:, col_ind));
    numUnique(isnan(numUnique)) = [];
    numDataLevels = numDataLevels + length(numUnique);
end

if numDataLevels == length(levels),
    if any(data(:) == 0),
        for k = 1:size(data, 2),
            data(:, k) = grp2idx(data(:, k));
        end
        out = dummyvar(data);
    else
        out = dummyvar(data);
    end
else
    % handle the case when there is only one level active, but there are actually several levels
    pseudoData = repmat([1:length(levels)/size(data, 2)]', [1 size(data, 2)]);
    data = [data; pseudoData];
    out = dummyvar(data);
    out((end-size(pseudoData, 1)+1):end, :) = [];
end


end