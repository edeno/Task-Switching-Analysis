function [designMatrix, gam] = gamModelMatrix(model_str, GLMCov, response, varargin)

inParser = inputParser;
inParser.addRequired('model_str', @ischar);
inParser.addRequired('GLMCov', @isstruct);
inParser.addRequired('response', @isvector);

inParser.parse(model_str, GLMCov, response, varargin{:});

gam = inParser.Results;
gam = rmfield(gam, {'GLMCov', 'response'});

% Parse into additive terms
addTerms = strtrim(regexp(model_str, '+', 'split'));

% Identify the smooth terms
parsedTerms = strtrim(regexp(addTerms, ',|=', 'split'));
isSmooth = cellfun(@(x) ~isempty(regexp(x{1}, 's\(.*', 'match')), parsedTerms, 'UniformOutput', false);
isSmooth = [isSmooth{:}];
% Strip any smooth function syntax
parsedTerms = cellfun(@(x) regexprep(x, '(s\()|(\))', ''), parsedTerms, 'UniformOutput', false);

% Replace smooth terms with the normal terms
addTerms = cellfun(@(x) x{1}, parsedTerms, 'UniformOutput', false);

% Parse for interactions within additive terms
interTerms = cellfun(@(x) strtrim(regexp(x, '*', 'split')), addTerms, 'UniformOutput', false);

% Now create the design matrix

designMatrix = [];
cov_names = [];
level_names = [];

sqrtPen = [];
constraints = [];
constraintLevel_names = [];
penalty = [];
bsplines = cell(size(addTerms));

constant_ind = [];

% Each additive Term
for curAdd = 1:length(addTerms),
    
    % Figure out how many multiplicative terms exist within each additive
    % term
    numVar = length(interTerms{curAdd});
    curInterTerms = interTerms{curAdd};
    
    data_ind = find(ismember({GLMCov.name}, curInterTerms));
    % sort data_ind in the same order as the addTerms
    GLMCov_name = {GLMCov(data_ind).name};
    hash_map =  containers.Map(curInterTerms, 1:numVar);
    sort_ind = cell2mat(values(hash_map, GLMCov_name));
    data_ind = data_ind(sort_ind);
    
    data = {GLMCov(data_ind).data};
    levels = {GLMCov(data_ind).levels};
    
    isCategorical = [GLMCov(data_ind).isCategorical];
    
    % Convert to dummy variables and append a column of ones to the data
    data = dummyVar(data, isCategorical, 'Reference');
    
    numLevels = cellfun(@(x) 1:length(x), levels, 'UniformOutput', false);
    
    % Figure out all the relevant interactions
    if length(numLevels) < 2,
        if isempty(data)
            data = {ones(size(response))};
            levels = {'(Intercept)'};
        end
        data_temp = data{:};
        levels_temp = levels{:};
    else
        [rep] = allpairs2(numLevels);
        data = cellfun(@(data, rep) data(:, rep), data, rep, 'UniformOutput', false);
        levels = cellfun(@(levels, rep) levels(:, rep), levels, rep, 'UniformOutput', false);
        
        data_temp = data{1};
        levels_temp = levels{1};
        
        for var_ind = 2:numVar,
            data_temp = data_temp.*data{var_ind};
            levels_temp = strcat(levels_temp, ':', levels{var_ind});
        end
        
    end
    
    numLevels = size(data_temp, 2);
    
    cov_names_temp = repmat(addTerms(curAdd), 1, numLevels);
    sqrtPen_temp = repmat({1}, 1, numLevels);
    constraints_temp = repmat({1}, 1, numLevels);
    constraintLevel_temp = levels_temp;
    penalty_temp = repmat({1}, 1, numLevels);
    constant_ind = [constant_ind true(1, numLevels)];
    
    % Deal with Smoothing
    if isSmooth(curAdd),
        smoothParams = parsedTerms{curAdd};
        % Convert numbers from strings
        value = str2double(smoothParams);
        smoothParams(~isnan(value)) = {value(~isnan(value))};
        
        % Find smoothing factor
        smoothingFactor.data = GLMCov(ismember({GLMCov.name}, smoothParams{2})).data;
        smoothingFactor.name = smoothParams{2};
        smoothParams{2} = smoothingFactor;
        
        factor.name = addTerms{curAdd};
        factor.data = {GLMCov(data_ind).data};
        factor.levels = {GLMCov(data_ind).levels};
        
        smoothParams{1} = factor;
        
        [smoothMatrix, bsplines{curAdd}, smoothCov_name, smoothLevel_names, ...
            smoothSqrtPen, smoothConstraints, smoothPenalty, smoothConNames] = factorBySpline(smoothParams{:});
        
        data_temp = [data_temp smoothMatrix];
        levels_temp = [levels_temp smoothLevel_names];
        cov_names = [cov_names smoothCov_name];
        sqrtPen_temp = [sqrtPen_temp smoothSqrtPen];
        constraints_temp = [constraints_temp smoothConstraints];
        penalty_temp = [penalty_temp smoothPenalty];
        constraintLevel_temp = [constraintLevel_temp smoothConNames];
        constant_ind = [constant_ind false(1, size(smoothMatrix, 2))];
    end
    
    % Add To Design Matrix
    designMatrix = [designMatrix data_temp];
    cov_names = [cov_names cov_names_temp];
    level_names = [level_names levels_temp];
    sqrtPen = [sqrtPen sqrtPen_temp];
    penalty = [penalty penalty_temp];
    constraints = [constraints constraints_temp];
    constraintLevel_names = [constraintLevel_names constraintLevel_temp];
end

% Fix Penalty Intercept
sqrtPen(1) = {0};
penalty(1) = {0};

% Convert to matrix
sqrtPen = blkdiag(sqrtPen{:});
penalty = blkdiag(penalty{:});
constraints = blkdiag(constraints{:});

designMatrix(isnan(designMatrix)) = 0;

% Remove Duplicates
dup_ind = findDuplicateColumns(designMatrix);

designMatrix(:, dup_ind) = [];
level_names(:, dup_ind) = [];
cov_names(:, dup_ind) = [];
sqrtPen(dup_ind, :) = [];
sqrtPen(:, dup_ind) = [];
penalty(dup_ind, :) = [];
penalty(:, dup_ind) = [];
constraints(:, dup_ind) = [];
constant_ind(:, dup_ind) = [];

bad_ind = sum(constraints, 2) == 0;
constraints(bad_ind, :) = [];
constraintLevel_names(:, bad_ind) = [];

% Rename first term to intercept
level_names{1} = '(Intercept)';
cov_names{1} = '(Intercept)';

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
function [dummy] = dummyVar(data, isCategorical, type)

dummy = cell(size(data));

switch(type)
    case 'Full' % symmetric coding, no reference level
        dummy(isCategorical) = cellfun(@(x) dummyvar(grp2idx(x)), data(isCategorical), 'UniformOutput', false);
        dummy = cellfun(@(x) [ones(size(x,1), 1) x], dummy, 'UniformOutput', false);
    case 'Reference' % first level is the reference
        dummy(isCategorical) = cellfun(@(x) dummyvar(grp2idx(x)), data(isCategorical), 'UniformOutput', false);
        dummy(isCategorical) = cellfun(@(x) [ones(size(x,1), 1) x(:, 2:end)], dummy(isCategorical), 'UniformOutput', false);
        dummy(~isCategorical) = cellfun(@(x) [ones(size(x,1), 1) x], data(~isCategorical), 'UniformOutput', false);
end

end
%-----------------------------------------------------------------------------
function [ixDupRows] = findDuplicateColumns(x)

x = x';
[~,I,~] = unique(x, 'rows', 'first');
ixDupRows = setdiff(1:size(x,1), I);

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
inParser.addParamValue('ridgeLambda', .5, @(x) isnumeric(x) && x >= 0);
inParser.addParamValue('knots', [], @isvector);

inParser.parse(factor, varargin{:});

by = inParser.Results;

if isempty(factor.data)
    factor.data = {ones(size(by.smoothingFactor.data))};
    factor.levels = {{''}};
end

numVar = length(factor.data);
data = dummyVar(factor.data, true(numVar, 1), 'Full');
smoothLevels = cellfun(@(x) [{''} x], factor.levels, 'UniformOutput', false);
numLevels = cellfun(@(x) 1:length(x), smoothLevels, 'UniformOutput', false);

if length(numLevels) < 2,
    
    smoothData_temp = data{:};
    smoothLevels_temp = smoothLevels{:};
else
    
    % Figure out all the relevant interactions
    [rep] = allpairs2(numLevels);
    data = cellfun(@(data, rep) data(:, rep), data, rep, 'UniformOutput', false);
    smoothLevels = cellfun(@(levels, rep) levels(:, rep), smoothLevels, rep, 'UniformOutput', false);
    
    smoothData_temp = data{1};
    smoothLevels_temp = smoothLevels{1};
    
    for var_ind = 2:numVar,
        smoothData_temp = smoothData_temp.*data{var_ind};
        smoothLevels_temp = strcat(smoothLevels_temp, ':', smoothLevels{var_ind});
    end
end
smoothData_temp = smoothData_temp(:, 2:end);
smoothLevels_temp = smoothLevels_temp(2:end);
smoothLevels_temp = regexprep(smoothLevels_temp, '(^:)|(:$)', '');

numLevels = size(smoothData_temp, 2);

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

covLevel_names = repmat(smoothLevels_temp, [bsplines.basis_dim-1 1]);
covLevel_names = covLevel_names(:)';
covLevel_names = strcat(covLevel_names, ['.' by.smoothingFactor.name]);
level_no = num2cell(repmat(1:bsplines.basis_dim-1, [1 numLevels]));
level_no = cellfun(@(x) num2str(x), level_no, 'UniformOutput', false);
covLevel_names = strcat(covLevel_names, '.', level_no);

constraintLevel_names = repmat(smoothLevels_temp, [bsplines.basis_dim 1]);
constraintLevel_names = constraintLevel_names(:)';
constraintLevel_names = strcat(constraintLevel_names, ['.' by.smoothingFactor.name]);
level_no = num2cell(repmat(1:bsplines.basis_dim, [1 numLevels]));
level_no = cellfun(@(x) num2str(x), level_no, 'UniformOutput', false);
constraintLevel_names = strcat(constraintLevel_names, '.', level_no);

for level_ind = 1:numLevels,
    level_idx = (level_ind-1)*(bsplines.basis_dim-1) + [1:bsplines.basis_dim-1];
    X(:, level_idx) = [bsxfun(@times, smoothData_temp(:, level_ind), bsplines.con_basis)];
end


end