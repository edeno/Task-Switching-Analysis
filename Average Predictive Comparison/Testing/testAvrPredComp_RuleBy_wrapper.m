function [avpred] = testAvrPredComp_RuleBy_wrapper(model_dir, gamParams, by_name, session_name, timePeriod, numSim, numSamples, main_dir)

apc_dir = [model_dir, '/APC'];
save_folder = [apc_dir, '/RuleBy_', by_name, '/'];
if ~exist(save_folder, 'dir'),
    mkdir(save_folder);
end

[avpred] = avrPredComp_RuleBy(session_name, timePeriod, gamParams.regressionModel_str, by_name, numSim, numSamples, save_folder, main_dir);
end