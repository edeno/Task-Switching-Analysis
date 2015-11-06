function [stats] = gamStats(designMatrix, y, fitInfo, trial_id, varargin)

inParser = inputParser;
inParser.addParameter('extraFitPenalty', 1, @isvector); % set to 1.4 if want extra smoothing
inParser.addParameter('prior_weights', [], @isvector);
inParser.addParameter('Compact', false, @islogical);

inParser.parse(varargin{:});
stats = inParser.Results;

ssr = fitInfo.distrFun.ssr;

if isempty(stats.prior_weights)
    prior_weights = ones(size(y));
else
    prior_weights = stats.prior_weights;
end

extraFitPenalty = stats.extraFitPenalty;
N = fitInfo.N;
distr = fitInfo.gam.distr;
%%
mu = fitInfo.ilinkFun(fitInfo.gam.offset + designMatrix * fitInfo.con_beta);

isNan = isnan(mu) | isnan(y);
y(isNan) = [];
trial_id(isNan) = [];
mu(isNan) = [];
prior_weights(isNan) = [];
designMatrix(isNan, :) = [];

% Time Rescale
if strcmp(distr, 'poisson')
    lambdaInt = accumarray(trial_id, mu, [], @(m) {cumsum(m)}, {NaN}); % Integrated Intensity Function by Trial
    spikeInd = accumarray(trial_id, y, [], @(s) {find(s == 1)}); % Spike times by Trial
    rescaledISIs = cell2mat(cellfun(@(lI,sI) (diff([0; lI(sI)])), lambdaInt, spikeInd, 'UniformOutput', false)); % Integrated Intensities between successive spikes, aka rescaled ISIs
    maxTransformedInterval = cell2mat(cellfun(@(lI,sI) lI(end) - lI(sI), lambdaInt, spikeInd, 'UniformOutput', false)) + rescaledISIs; % correction for short intervals as in Wiener 2003 - Neural Computation
    
    uniformRescaledISIs = (1 - exp(-rescaledISIs)) ./ (1 - exp(-maxTransformedInterval)); % Convert Rescaled ISIs to Uniform Distribution (0, 1)
    uniformRescaledISIs(uniformRescaledISIs > (1 - 1E-6)) = (1 - 1E-6);
    uniformRescaledISIs(uniformRescaledISIs == 0) = 1E-6;
    normalRescaledISIs = norminv(uniformRescaledISIs, 0, 1); % Convert to normal distribution
    numSpikes = length(uniformRescaledISIs); % Number of Spikes
    
    if numSpikes > 0
        sortedKS = sort(uniformRescaledISIs, 'ascend');
        uniformCDFvalues = ([1:numSpikes] - 0.5)' / numSpikes;
        ksStat = max(abs(sortedKS - uniformCDFvalues));
    else
        ksStat = 1;
        uniformCDFvalues = [];
    end
    stats.timeRescale.uniformCDFvalues = uniformCDFvalues;
    stats.timeRescale.sortedKS = sortedKS;
    stats.timeRescale.ksStat = ksStat;
    stats.timeRescale.numSpikes = numSpikes;
    stats.timeRescale.rescaledISIs = rescaledISIs;
    stats.timeRescale.uniformRescaledISIs = uniformRescaledISIs;
    stats.timeRescale.normalRescaledISIs = normalRescaledISIs;
end

% Deviance
di = fitInfo.distrFun.devFun(mu,y,N);
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
xw_r = bsxfun(@times,designMatrix,fitInfo.sqrtw);
[~, R] = qr(xw_r,0);
[u, d, v] = svd([R; fitInfo.sqrtPenMatrix], 0);

keepCols = diag(d) > (abs(d(1)) .* max(fitInfo.numData,fitInfo.numParam) .* eps(class(d)));
d = d(keepCols, keepCols);
v = v(:, keepCols);
u = u(:, keepCols);

u1 = u(1:fitInfo.numParam, :);
% effective degrees of freedom edf = trace(u1*u1'); runs out of memory if computed directly
edf = sum(u1(:) .* u1(:));
stats.edf = edf;

%% Theoretical Bias-Corrected Performance Measures
stats.AIC = Dev + (2 * extraFitPenalty * edf);
stats.BIC = Dev + (log(fitInfo.numData) * extraFitPenalty * edf);
stats.GCV = (fitInfo.numData * Dev) / (fitInfo.numData - extraFitPenalty * edf)^2;
if strcmp(distr, 'poisson') || strcmp(distr, 'binomial'),
    stats.UBRE = (Dev / fitInfo.numData) + ((2 * extraFitPenalty * edf)/ fitInfo.numData) - 1; % Scaled AIC
end

stats.anscresid = fitInfo.distrFun.anscresid(mu,y,N);
stats.resid = fitInfo.distrFun.resid(mu,y,N);

if edf > 0
    ssr = ssr(mu,y,prior_weights);
    stats.sfit = sqrt(ssr / (fitInfo.numData - edf));
else
    stats.sfit = NaN;
end
if ~fitInfo.estdisp
    stats.s = 1;
    stats.estdisp = false;
else
    stats.s = stats.sfit;
    stats.estdisp = true;
end

PKt = v * diag(diag(d).^(-1)) * u1'; % v * d^(-1) * u1
Ve = PKt * PKt'; % Frequentist Covariance Sandwich Estimator
if fitInfo.estdisp, Ve = Ve * stats.s^2; end

covb = Ve;

covb = fitInfo.gam.constraints * covb * fitInfo.gam.constraints';

se = sqrt(diag(covb)); se = se(:);   % insure vector even if empty
stats.se = se;

stats.covb = covb;

stats.coeffcorr = zeros(size(covb));
stats.coeffcorr = covb ./ (se * se');
stats.t = fitInfo.beta ./ se;

if fitInfo.estdisp
    stats.p = 2 * tcdf(-abs(stats.t), edf);
else
    stats.p = 2 * normcdf(-abs(stats.t));
end

end
