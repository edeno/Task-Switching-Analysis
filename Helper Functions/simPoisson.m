function [y] = simPoisson(rate, dt)

y = rand(size(rate)) <= (rate*dt);
y = double(y);

end