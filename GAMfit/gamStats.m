function [stats] = gamStats(designMatrix, y, fitInfo, trial_id, varargin)

inParser = inputParser;
inParser.addRequired('designMatrix', @ismatrix);
inParser.addRequired('y', @ismatrix);
inParser.addRequired('fitInfo', @isstruct);
inParser.addRequired('trial_id', @ismatrix);
inParser.addParamValue('extraFitPenalty', 1, @isvector); % set to 1.4 if want extra smoothing
inParser.addParamValue('prior_weights', [], @isvector);
inParser.addParamValue('Compact', false, @islogical);

inParser.parse(designMatrix, y, fitInfo, trial_id, varargin{:});
stats = inParser.Results;
stats = rmfield(stats, {'designMatrix','y','trial_id'});

sqrtw = fitInfo.sqrtw;
sqrtPenMatrix = fitInfo.sqrtPenMatrix;
numData = fitInfo.numData;
numParam = fitInfo.numParam;
devFun = fitInfo.distrFun.devFun;
ssr = fitInfo.distrFun.ssr;
anscresid = fitInfo.distrFun.anscresid;
resid = fitInfo.distrFun.resid;
estdisp = fitInfo.estdisp;
constraints = fitInfo.gam.constraints;
beta = fitInfo.beta;
con_beta = fitInfo.con_beta;
ilinkFun = fitInfo.ilinkFun;
offset = fitInfo.gam.offset;

if isempty(stats.prior_weights)
    prior_weights = fitInfo.gam.prior_weights;
    
    if isempty(prior_weights),
        prior_weights = ones(size(y));
    end
    
else
    prior_weights = stats.prior_weights;
end

extraFitPenalty = stats.extraFitPenalty;
N = fitInfo.N;
distr = fitInfo.gam.distr;
%%
mu = ilinkFun(offset + designMatrix*con_beta);

isNan = isnan(mu) | isnan(y);
y(isNan) = [];
trial_id(isNan) = [];
mu(isNan) = [];
prior_weights(isNan) = [];
designMatrix(isNan, :) = [];

% Time Rescale
if strcmp(distr, 'poisson')
    lambdaInt = accumarray(trial_id, mu, [], @(x) {cumsum(x)}, {NaN}); % Integrated Intensity Function by Trial
    spikeInd = accumarray(trial_id, y, [], @(x) {find(x == 1)}); % Spike times by Trial
    rescaledISIs = cell2mat(cellfun(@(x,y) (diff([0; x(y)])), lambdaInt, spikeInd, 'UniformOutput', false)); % Integrated Intensities between successive spikes, aka rescaled ISIs
    maxTransformedInterval = cell2mat(cellfun(@(x,y) x(end) - x(y), lambdaInt, spikeInd, 'UniformOutput', false)) + rescaledISIs; % correction for short intervals as in Wiener 2003 - Neural Computation
    
    uniformRescaledISIs = (1 - exp(-rescaledISIs)) ./ (1 - exp(-maxTransformedInterval)); % Convert Rescaled ISIs to Uniform Distribution (0, 1)
    normalRescaledISIs = norminv(uniformRescaledISIs, 0, 1); % Convert to normal distribution
    numSpikes = length(uniformRescaledISIs); % Number of Spikes
    
    if numSpikes > 0
        %     autoCorr = xcorr(normalRescaledISIs, 'coef');
       sortedKS = sort(uniformRescaledISIs, 'ascend');
       uniformCDFvalues = ([1:numSpikes] - 0.5)' / numSpikes;
       ksStat = max(abs(sortedKS - uniformCDFvalues));
    else
        ksStat = 1;
        uniformCDFvalues = [];
        % autoCorr = [];
    end
    
    stats.timeRescale.uniformCDFvalues = uniformCDFvalues;
    stats.timeRescale.sortedKS = sortedKS;
    stats.timeRescale.ksStat = ksStat;
    stats.timeRescale.numSpikes = numSpikes;
    stats.timeRescale.rescaledISIs = rescaledISIs;
    stats.timeRescale.uniformRescaledISIs = uniformRescaledISIs;
    stats.timeRescale.normalRescaledISIs = normalRescaledISIs;
    %     stats.autoCorr = autoCorr;
end

% Deviance
di = devFun(mu,y,N);
Dev = sum(prior_weights .* di);

stats.Dev = Dev;
if numSpikes > 0
    [stats.fp, stats.tp, ~, stats.AUC] = perfcurve(y, mu, 1);
else
    stats.fp = NaN;
    stats.tp = NaN;
    stats.AUC = NaN;
end

% stats.AUC_rescaled = 2 * (stats.AUC - .5);

% Mutual Information
if numSpikes > 0 && strcmp(distr, 'poisson'),
    log2Likelihood = @(r, lambda) r' * log2(lambda) - sum(lambda); % Poisson only
    stats.mutual_information = (log2Likelihood(y, mu) - log2Likelihood(y, ones(size(y)) * nanmean(y))) / numSpikes; % bits/spike
else
    stats.mutual_information = NaN;
end

if stats.Compact,
    return;
end
%% Get effective degrees of freedom (trace of the influence "hat" matrix a)
xw_r = bsxfun(@times,designMatrix,sqrtw);
[~, R] = qr(xw_r,0);
[u, d, v] = svd([R; sqrtPenMatrix], 0);

keepCols = diag(d) > abs(d(1)).*max(numData,numParam).*eps(class(d));
d = d(keepCols, keepCols);
v = v(:, keepCols);
u = u(:, keepCols);

u1 = u(1:numParam, :);
% effective degrees of freedom edf = trace(u1*u1'); runs out of memory if computed directly
edf = sum(u1(:).*u1(:));
stats.edf = edf;

%% Theoretical Bias-Corrected Performance Measures
stats.AIC = Dev + 2*extraFitPenalty*edf;
stats.BIC = Dev + log(numData)*extraFitPenalty*edf;
stats.GCV = (numData*Dev) / (numData - extraFitPenalty*edf)^2;
if strcmp(distr, 'poisson') || strcmp(distr, 'binomial'),
    stats.UBRE = (Dev/numData) + ((2*extraFitPenalty*edf)/numData) - 1; % Scaled AIC
end

stats.anscresid = anscresid(mu,y,N);
stats.resid = resid(mu,y,N);

if edf > 0
    ssr = ssr(mu,y,prior_weights);
    stats.sfit = sqrt(ssr / (numData - edf));
else
    stats.sfit = NaN;
end
if ~estdisp
    stats.s = 1;
    stats.estdisp = false;
else
    stats.s = stats.sfit;
    stats.estdisp = true;
end

PKt = v * diag(diag(d).^(-1)) * u1'; % v * d^(-1) * u1
Ve = PKt * PKt'; % Frequentist Covariance Sandwich Estimator
if estdisp, Ve = Ve * stats.s^2; end

covb = Ve;

covb = constraints * covb * constraints';

se = sqrt(diag(covb)); se = se(:);   % insure vector even if empty
stats.se = se;

stats.covb = covb;

stats.coeffcorr = zeros(size(covb));
stats.coeffcorr = covb ./ (se * se');
stats.t = beta ./ se;

if estdisp
    stats.p = 2 * tcdf(-abs(stats.t), edf);
else
    stats.p = 2 * normcdf(-abs(stats.t));
end

end
