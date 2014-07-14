clear all; close all; clc;

regressionModel_str = 'Rule * Switch History + Rule * Previous Error History + Rule * Test Stimulus + Normalized Prep Time';
timePeriod = 'Rule Response';
main_dir = '/data/home/edeno/Task Switching Analysis';
numSim = 1000;
numSamples = 50000;
overwrite = true;

computeAPC_rule(regressionModel_str, timePeriod, main_dir, 'numSim', numSim, ...
    'numSamples', numSamples, 'overwrite', overwrite)
computeAPC_rulepreverror(regressionModel_str, timePeriod, main_dir, 'numSim', numSim, ...
    'numSamples', numSamples, 'overwrite', overwrite)
computeAPC_ruleswitch(regressionModel_str, timePeriod, main_dir, 'numSim', numSim, ...
    'numSamples', numSamples, 'overwrite', overwrite)