clear all; close all; clc;
numSamples = 20000;
dt = 1E-3;
rate = 5 * ones(numSamples, 1);
trial_time = 0:dt:(length(rate) * dt);
[y] = simPoisson(rate, dt);

intRate = cumsum(rate * dt);
rescaledISI = diff([0; intRate(y == 1)]);
uniformISI = sort(1 - exp(-rescaledISI), 'ascend');
n = length(uniformISI);
x = ([1:n] - .5) / n;
ci = 1.36/sqrt(n);

figure;

subplot(1,3,1);
hist(rescaledISI, 50);
box off;
title('Exponential ISIs');

subplot(1,3,2);
hist(uniformISI, 50);
box off;
title('Uniform ISIs');

subplot(1,3,3);
hold all;
plot(x, x + ci, 'k:');
plot(x, x - ci, 'k:');
axis([0 1 0 1]);
line;
plot(x, uniformISI);
box off;
axis square
title('KS Plot');

%%

expRV = random('exp', 1, [1 numSamples]);
uniRV = 1 - exp(-expRV);
sortedRV = sort(uniRV, 'ascend');
n = length(sortedRV);
x = ([1:n] - 0.5) / n;
ci = 1.36/sqrt(n);

figure;

subplot(1,3,1);
hist(expRV, 50);
box off;
title('Exponential ISIs');

subplot(1,3,2);
hist(uniRV, 50);
box off;
title('Uniform ISIs');

subplot(1,3,3);
hold all;
plot(x, x + ci, 'k:');
plot(x, x - ci, 'k:');
axis([0 1 0 1]);
line;
plot(x, sortedRV);
title('KS Test');

%% Show the bias in time rescaling with shorter trials
% Shorter trials implies censoring of longer interspike intervals
% The comparison to a exponential distribution with mean one gets messed up because of
% this censoring.

for trialLength = 300:500:5000,
    numTrials = 2000;
    dt = 1E-3;
    rate = 5 * ones(numTrials * trialLength, 1);
    trial_id = bsxfun(@times, [1:numTrials], ones(trialLength, 1));
    trial_id = trial_id(:);
    trial_time = 0:dt:(trialLength * dt);
    y = simPoisson(rate, dt);
    
    mu = rate * dt;
    
    lambdaInt = accumarray(trial_id, mu, [], @(x) {cumsum(x)}, {NaN}); % Integrated Intensity Function by Trial
    trialMaxTime = accumarray(trial_id, mu, [], @(x) {length(x)}, {NaN}); % Integrated Intensity Function by Trial
    spikeInd = accumarray(trial_id, y, [], @(x) {find(x == 1)}); % Spike times by Trial
    rescaledISIs = cell2mat(cellfun(@(x,y) (diff([0; x(y)])), lambdaInt, spikeInd, 'UniformOutput', false)); % Integrated Intensities between successive spikes, aka rescaled ISIs
    
    uniformRescaledISIs = 1 - exp(-rescaledISIs); % Convert Rescaled ISIs to Uniform Distribution (0, 1)
    numSpikes = length(uniformRescaledISIs); % Number of Spikes
    sortedKS = sort(uniformRescaledISIs, 'ascend');
    uniformCDFvalues = ([1:numSpikes] - 0.5)' / numSpikes;
    
    ci = 1.36/sqrt(numSpikes);
    
    figure;
    
    subplot(1,3,1);
    hist(rescaledISIs, 50);
    box off;
    title('Exponential ISIs');
    
    subplot(1,3,2);
    hist(uniformRescaledISIs, 50);
    box off;
    title('Uniform ISIs');
    xlim([0 1]);
    
    subplot(1,3,3);
    hold all;
    plot(uniformCDFvalues, uniformCDFvalues + ci, 'k:');
    plot(uniformCDFvalues, uniformCDFvalues - ci, 'k:');
    axis([0 1 0 1]);
    line;
    plot(uniformCDFvalues, sortedKS);
    box off;
    axis square
    title('KS Plot');
    suptitle(sprintf('Trial Length: %d', trialLength));
end

%% Rescale the censored interval to be uniform as in Wiener 2003 - Neural Computation
% "An Adjustment to the Time-Rescaling Method for Application to
% Short-Trial Spike Train Data"

for trialLength = 300:500:5000,
    numTrials = 2000;
    dt = 1E-3;
    rate = 5 * ones(numTrials * trialLength, 1);
    trial_id = bsxfun(@times, [1:numTrials], ones(trialLength, 1));
    trial_id = trial_id(:);
    trial_time = 0:trialLength-1;
    y = simPoisson(rate, dt);
    toUniform = @(x) 1 - exp(-1 * x);
    
    mu = rate * dt;
    % mu = exp(glmfit(ones(size(y)), y, 'poisson', 'const', 'off'));
    
    lambdaInt = accumarray(trial_id, mu, [], @(x) {cumsum(x)}, {NaN}); % Integrated Intensity Function by Trial
    spikeInd = accumarray(trial_id, y, [], @(x) {find(x == 1)}); % Spike times by Trial
    rescaledISIs = cell2mat(cellfun(@(x,y) (diff([0; x(y)])), lambdaInt, spikeInd, 'UniformOutput', false)); % Integrated Intensities between successive spikes, aka rescaled ISIs
    maxTransformedInterval = cell2mat(cellfun(@(x,y) x(end) - x(y), lambdaInt, spikeInd, 'UniformOutput', false)) + rescaledISIs;
    
    uniformRescaledISIs = toUniform(rescaledISIs) ./ toUniform(maxTransformedInterval); % Convert Rescaled ISIs to Uniform Distribution (0, 1)
    numSpikes = length(uniformRescaledISIs); % Number of Spikes
    sortedKS = sort(uniformRescaledISIs, 'ascend');
    uniformCDFvalues = ([1:numSpikes] - 0.5)' / numSpikes;
    
    ci = 1.36/sqrt(numSpikes);
    
    figure;
    
    subplot(2,2,1);
    hist(toUniform(rescaledISIs), 50);
    box off;
    title('Unscaled Uniform ISIs');
    xlim([0 1]);
    
    subplot(2,2,2);
    hist(toUniform(maxTransformedInterval), 50);
    box off;
    title('Max Transformed Interval');
    
    subplot(2,2,3);
    hist(uniformRescaledISIs, 50);
    box off;
    title('Scaled Uniform ISIs');
    
    subplot(2,2,4);
    hold all;
    plot(uniformCDFvalues, uniformCDFvalues + ci, 'k:');
    plot(uniformCDFvalues, uniformCDFvalues - ci, 'k:');
    axis([0 1 0 1]);
    line;
    plot(uniformCDFvalues, sortedKS);
    box off;
    axis square
    title('KS Plot');
    suptitle(sprintf('Trial Length: %d', trialLength));
end