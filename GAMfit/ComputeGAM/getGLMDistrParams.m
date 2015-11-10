function [distrFun] = getGLMDistrParams(distr)

switch distr
    case 'normal'
        distrFun.startMu = @(y, N) y;
        distrFun.sqrtvarFun = @(mu,N) ones(size(mu));
        distrFun.devFun = @(mu,y,N) (y - mu).^2;
        distrFun.ssr = @(mu,y,prior_wts) sum(prior_wts .* (y - mu).^2);
        distrFun.anscresid = @(mu,y,N) y - mu;
        distrFun.resid =  @(mu,y,N) (y - mu);
        distrFun.canonicalLink = 'identity';
    case 'binomial'
        distrFun.startMu = @(y, N)(N .* y + 0.5) ./ (N + 1);
        distrFun.sqrtvarFun = @(mu,N) sqrt(mu).*sqrt(1-mu) ./ sqrt(N);
        distrFun.devFun = @(mu,y,N) 2*N.*(y.*log((y+(y==0))./mu) + (1-y).*log((1-y+(y==1))./(1-mu)));
        distrFun.ssr = @(mu,y,prior_wts) sum(prior_wts .* (y - mu).^2 ./ (mu .* (1 - mu) ./ N));
        distrFun.anscresid = @(mu,y,N) beta(2/3,2/3) * ...
            (betainc(y,2/3,2/3)-betainc(mu,2/3,2/3)) ./ ((mu.*(1-mu)).^(1/6) ./ sqrt(N));
        distrFun.resid =  @(mu,y,N) (y - mu) .* N;
        distrFun.canonicalLink = 'logit';
    case 'poisson'
        distrFun.startMu = @(y, N) y + 0.25;
        distrFun.sqrtvarFun = @(mu,N) sqrt(mu);
        distrFun.devFun = @(mu,y,N) 2*(y .* (log((y+(y==0)) ./ mu)) - (y - mu));
        distrFun.ssr = @(mu,y,prior_wts) sum(prior_wts .* (y - mu).^2 ./ mu);
        distrFun.anscresid = @(mu,y,N) 1.5 * ((y.^(2/3) - mu.^(2/3)) ./ mu.^(1/6));
        distrFun.resid =  @(mu,y,N) (y - mu);
        distrFun.canonicalLink = 'log';
    case 'gamma'
        distrFun.startMu = @(y, N) max(y, eps(class(y))); % somewhat arbitrary
        distrFun.sqrtvarFun = @(mu,N) mu;
        distrFun.devFun = @(mu,y,N) 2*(-log(y ./ mu) + (y - mu) ./ mu);
        distrFun.ssr = @(mu,y,prior_wts) sum(prior_wts .* ((y - mu) ./ mu).^2);
        distrFun.anscresid = 3 * (y.^(1/3) - mu.^(1/3)) ./ mu.^(1/3);
        distrFun.resid =  @(mu,y,N) (y - mu);
        distrFun.canonicalLink = 'reciprocal';
    case 'inverse gaussian'
        distrFun.startMu = @(y, N) max(y, eps(class(y))); % somewhat arbitrary
        distrFun.sqrtvarFun = @(mu,N) mu.^(3/2);
        distrFun.devFun = @(mu,y,N) ((y - mu)./mu).^2 ./  y;
        distrFun.ssr = @(mu,y,prior_wts) sum(prior_wts .* ((y - mu) ./ mu.^(3/2)).^2);
        distrFun.anscresid = @(mu,y,N) (log(y) - log(mu)) ./ mu;
        distrFun.resid =  @(mu,y,N) (y - mu);
        distrFun.canonicalLink = -2;
end

end