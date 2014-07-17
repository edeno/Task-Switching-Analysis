clear all; close all; clc;

regressionModel_str = 'Rule * Switch History + Rule * Previous Error History + Rule * Congruency History + Response Direction + Rule * Normalized Prep Time';
timePeriod = 'Rule Response';
main_dir = '/data/home/edeno/Task Switching Analysis';
apc_dir = [main_dir, '/Processed Data/', timePeriod,'/Models/', regressionModel_str, '/APC/'];

covariate_type = dir(apc_dir);
covariate_type = {covariate_type.name};
covariate_type(ismember(covariate_type, {'.', '..'})) = [];
overwrite = true;

for cov_ind = 1:length(covariate_type),
    collectAPCs(regressionModel_str, timePeriod, main_dir, covariate_type{cov_ind}, 'overwrite', overwrite)
end