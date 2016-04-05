function [y] = simPoisson(rate, dt)
% A sequence of Bernoulli variables converges to Poisson in the limit of
% the samples
y = rand(size(rate)) <= (rate*dt);
y = double(y);

end