function [neurons, gam, designMatrix, spikes, model_dir] = testComputeGAMfit_wrapper(gamParams, Rate, GLMCov_name, timePeriod_dir, session_name)

% Simulate Spikes
dt = 1E-3;
spikes = simPoisson(Rate, dt);

% Append spikes to GLMCov file
save(GLMCov_name, 'spikes', '-append');

% Save directory
model_dir = sprintf('%s/Models/%s', timePeriod_dir, gamParams.regressionModel_str);
if ~exist(model_dir, 'dir'),
    mkdir(model_dir);
end

% Estimate GAM parameters
[neurons, gam, designMatrix] = ComputeGAMfit(timePeriod_dir, session_name, gamParams, model_dir);

end