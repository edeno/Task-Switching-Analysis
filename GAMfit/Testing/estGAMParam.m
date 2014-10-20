function [neurons, gam, designMatrix, spikes] = estGAMParam(Rate, GLMCov, model_name, trial_id, incorrect)

dt = 1E-3;
spikes = simPoisson(Rate, dt);
[designMatrix, gam] = gamModelMatrix(model_name, GLMCov, spikes);
spikes_temp = spikes;

designMatrix(incorrect, :) = [];
spikes(incorrect, :) = [];
trial_id(incorrect) = [];

% Setup
numFolds = 1;
ridgeLambda = 1;
smoothLambda = [];
trials = unique(trial_id);
if numFolds > 1,
    CVO = cvpartition(length(trials), 'Kfold', numFolds);
else
    CVO = [];
end

sqrtPen = gam.sqrtPen;
constraints = gam.constraints;
constant_ind = gam.constant_ind;

lambda_vec = nan(size(constant_ind));
lambda_vec(constant_ind) = ridgeLambda;
lambda_vec(~constant_ind) = smoothLambda;
lambda_vec(1) = 0;


if numFolds > 1
    training_idx = ismember(trial_id, trials(CVO.training));
    test_idx = ismember(trial_id, trials(CVO.test));
else
    training_idx = true(size(designMatrix, 1), 1);
    test_idx = true(size(designMatrix, 1), 1);
end

const = 'off';

[neurons(1).par_est, fitInfo] = fitGAM(designMatrix(training_idx, :), spikes(training_idx), sqrtPen, ...
    'lambda', lambda_vec, 'distr', 'poisson', 'constant', const, ...
    'constraints', constraints);

[neurons(1).stats] = gamStats(designMatrix, spikes, fitInfo, trial_id, ...
    'Compact', false);

neurons.wire_number = 1;
neurons.unit_number = 1;
neurons.pfc = 1;
neurons.monkey = 'Monkey';

spikes = spikes_temp;
end