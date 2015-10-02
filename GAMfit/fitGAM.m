function [beta, fitInfo]= fitGAM(x, y, sqrtPenMatrix, varargin)

%% Parse inputs and set parameters for fitting
inParser = inputParser;
inParser.addRequired('x', @ismatrix);
inParser.addRequired('y', @ismatrix);
inParser.addRequired('penaltyMatrix', @ismatrix);
inParser.addOptional('lambda', 1, @isnumeric);
inParser.addOptional('distr', 'normal', @ischar);
inParser.addOptional('link', 'canonical', @ischar);
inParser.addOptional('estdisp', false, @islogical);
inParser.addOptional('prior_weights', [], @isvector);
inParser.addOptional('offset', [], @isvector);
inParser.addOptional('constraints', 1, @ismatrix);
inParser.addOptional('constant', 'on', @ischar);

inParser.parse(x, y, sqrtPenMatrix, varargin{:});

gam = inParser.Results;
gam = rmfield(gam, {'x','y', 'penaltyMatrix'});
lambda = gam.lambda;
distr = gam.distr;
link = gam.link;
if ismember(distr, {'normal', 'gamma'}),
    estdisp = true;
else
    estdisp = gam.estdisp;
end
prior_weights = gam.prior_weights;
const = gam.constant;
offset = gam.offset;
constraints = gam.constraints;
sqrtPenMatrix = bsxfun(@times, sqrt(lambda), sqrtPenMatrix);
augmented_y = zeros(size(sqrtPenMatrix, 1), 1);

converged = false;

% Check the response
[y, N] = checkResponse(y, distr);

% Set distribution-specific defaults.
[distrFun] = getGLMDistrParams(distr);

startMu = distrFun.startMu;
sqrtvarFun = distrFun.sqrtvarFun;
if strcmp(link, 'canonical'),
   link = distrFun.canonicalLink;
end

% Remove missing values from the data.  Also turns row vectors into columns.
[anybad,~,y,x,offset,prior_weights,N] = removeNaN(y,x,offset,prior_weights,N);
if anybad > 0
    badStr = {'', 'Covariate', 'Offset', 'Prior Weights', ''};
    error('GAMfit: %s size mismatch', badStr{anybad})
end

if strcmp(const,'on')
    x = [ones(size(x,1),1) x];
end
dataClass = superiorfloat(x,y);
x = cast(x,dataClass);
y = cast(y,dataClass);

[numData,numParam] = size(x);

if isempty(prior_weights)
    prior_weights = ones(size(y));
elseif any(prior_weights == 0)
    % A zero weight means ignore the observation, so n is reduced by one.
    % Residuals will be computed, however.
    numData = numData - sum(prior_weights == 0);
end
if isempty(offset), offset = 0; gam.offset = 0; end
if isempty(N), N = 1; end

% Instantiate functions for one of the canned links, or validate a
% user-defined link specification.
[linkFun,dlinkFun,ilinkFun] = testlink(link,dataClass);

% Initialize mu and eta from y.
mu = startMu(y,N);
eta.new = dlinkFun(mu);
eta.current = linkFun(mu);
beta = zeros(numParam,1,dataClass);
warned = false;

% Enforce limits on mu to guard against an inverse link that doesn't map into
% the support of the distribution.
switch distr
    case 'binomial'
        % mu is a probability, so order one is the natural scale, and eps is a
        % reasonable lower limit on that scale (plus it's symmetric).
        muLims = [eps(dataClass) 1-eps(dataClass)];
    case {'poisson' 'gamma' 'inverse gaussian'}
        % Here we don't know the natural scale for mu, so make the lower limit
        % small.  This choice keeps mu^4 from underflowing.  No upper limit.
        muLims = realmin(dataClass).^.25;
end

maxIter = 20;
tol = 1E-6;
augmented_weights = ones(size(sqrtPenMatrix, 1), 1);

fullX =  [x; sqrtPenMatrix];

%% Begin fitting
for iter = 1:maxIter,
    
    % Compute adjusted dependent variable for least squares fit
    deta = dlinkFun(mu);
    pseudoData = eta.current + (y - mu) .* deta;
    
    % Compute IRLS weights the inverse of the variance function
    sqrtirls = abs(deta) .* sqrtvarFun(mu, N);
    sqrtw = sqrt(prior_weights) ./ sqrtirls;
    
    % If the weights have an enormous range, we won't be able to do IRLS very
    % well.  The prior weights may be bad, or the fitted mu's may have too
    % wide a range, which is probably because the data do as well, or because
    % the link function is trying to go outside the distribution's support.
    wtol = max(sqrtw) * eps(dataClass)^(2/3);
    t = (sqrtw < wtol);
    if any(t)
        t = t & (sqrtw ~= 0);
        if any(t)
            sqrtw(t) = wtol;
            if ~warned
                %                 warning(message('stats:glmfit:BadScaling'));
            end
            warned = true;
        end
    end
    
    fullY = [pseudoData - offset; augmented_y];
    fullWeights = [sqrtw; augmented_weights];
    beta = wfit(fullY, fullX, fullWeights);
    eta.new = offset + (x * beta);
    dz = max(abs(eta.current - eta.new));
    
    % Compute predicted mean using inverse link function
    mu = ilinkFun(eta.new);
    
    % Force mean in bounds, in case the link function is a wacky choice
    switch distr
        case 'binomial'
            if any(mu < muLims(1) | muLims(2) < mu)
                mu = max(min(mu,muLims(2)),muLims(1));
            end
        case {'poisson' 'gamma' 'inverse gaussian'}
            if any(mu < muLims(1))
                mu = max(mu,muLims(1));
            end
    end
    
    eta.current = eta.new;
    
    if(dz < tol),
        converged = true;
        break;
    end
    
    if iter == maxIter,
        warning('Iteration Limit Reached'); 
    end
end

xw_r = bsxfun(@times,x,sqrtw);
[~, R] = qr(xw_r,0);
[u, d, ~] = svd([R; sqrtPenMatrix], 0);

% Keep the linearly independent columns using svd
keepCols = diag(d) > (abs(d(1)) .* max(numData,numParam) .* eps(class(d)));
u = u(:, keepCols);

u1 = u(1:numParam, :);
% effective degrees of freedom edf = trace(u1 * u1'); runs out of memory if computed directly
edf = sum(u1(:) .* u1(:));

%% Return fitInfo for diagnostics
fitInfo.sqrtw = sqrtw;
fitInfo.sqrtPenMatrix = sqrtPenMatrix;
fitInfo.numData = numData;
fitInfo.numParam = numParam;
fitInfo.mu = mu;
fitInfo.converged = converged;
fitInfo.estdisp = estdisp;
fitInfo.gam = gam;
fitInfo.con_beta = beta;
fitInfo.ilinkFun = ilinkFun;
fitInfo.N = N;
fitInfo.edf = edf;

beta = constraints * beta;

fitInfo.beta = beta;
fitInfo.distrFun = distrFun;


end

function [b] = wfit(y,x,sw)
% Perform a weighted least squares fit
[nrowx,ncolx] = size(x);
yw = y .* sw;
xw = x .* sw(:,ones(1,ncolx));

[Q, R, perm] = qr(xw,0);

z = Q'*yw;
% Use the rank-revealing QR to keep the linearly independent columns of XW.
keepCols = abs(diag(R)) > (abs(R(1)) .* max(nrowx,ncolx) .* eps(class(R)));

rankXW = sum(keepCols);
if rankXW < ncolx
    R = R(keepCols,keepCols);
    z = z(keepCols,:);
    perm = perm(keepCols);
end

% Compute the LS coefficients, filling in zeros in elements corresponding
% to rows of R that were thrown out.
bb = R \ z;

b = zeros(ncolx,1);
b(perm) = bb;

end

function [y, N] = checkResponse(y, distr)

N = [];

switch distr
    case 'normal'
    case 'binomial'
        if size(y,2) == 1
            % N will get set to 1 below
            if any(y < 0 | y > 1)
                error(message('stats:glmfit:BadDataBinomialFormat'));
            end
        elseif size(y,2) == 2
            y(y(:,2)==0,2) = NaN;
            N = y(:,2);
            y = y(:,1) ./ N;
            if any(y < 0 | y > 1)
                error(message('stats:glmfit:BadDataBinomialRange'));
            end
        else
            error(message('stats:glmfit:MatrixOrBernoulliRequired'));
        end
        
    case 'poisson'
        if any(y < 0)
            error(message('stats:glmfit:BadDataPoisson'));
        end
    case 'gamma'
        if any(y <= 0)
            error(message('stats:glmfit:BadDataGamma'));
        end
    case 'inverse gaussian'
        if any(y <= 0)
            error(message('stats:glmfit:BadDataInvGamma'));
        end
end

end

