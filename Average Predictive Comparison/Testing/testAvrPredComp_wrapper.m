function [avpred] = testAvrPredComp_wrapper(model_dir, gamParams, factor_name, session_name, timePeriod, numSim, numSamples, main_dir)

apc_dir = [model_dir, '/', gamParams.regressionModel_str, '/APC'];
save_folder = [apc_dir, '/', factor_name, '/'];
if ~exist(save_folder, 'dir'),
    mkdir(save_folder);
end

[avpred] = avrPredComp(session_name, timePeriod, gamParams.regressionModel_str, factor_name, numSim, numSamples, save_folder, main_dir);

end