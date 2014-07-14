clear all; close all; clc;

regressionModel_str = 'Rule * Switch History + Rule * Previous Error History + Rule * Congruency History + Response Direction + Normalized Prep Time';
timePeriod = 'Rule Response';
main_dir = '/data/home/edeno/Task Switching Analysis';
numSim = 1000;
numSamples = 50000;
overwrite = true;
type = {'RuleCongruency2', 'RulePrevError2', 'RuleSwitch2', 'PrevError2', ...
     'Congruency2', 'Switch2', 'Rule2', 'ResponseDir2', 'RulePrevError2_low', 'RuleCongruency2_low'};

for type_ind = 1:length(type),
    computeAPC(regressionModel_str, timePeriod, main_dir, type{type_ind}, 'numSim', numSim, ...
        'numSamples', numSamples, 'overwrite', overwrite)
end