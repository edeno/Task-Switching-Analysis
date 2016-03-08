%% Compiles the standalone
workingDir = '/projectnb/pfc-rule/Task-Switching-Analysis/';
addpath(genpath(workingDir));
cd(sprintf('%s/Average-Predictive-Comparison/Standalone', workingDir));
make computeAPCRuleBy_makefile
delete('run_computeAPCRuleByExec*.sh')
