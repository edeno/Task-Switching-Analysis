%% Compiles the standalone
workingDir = '/projectnb/pfc-rule/Task-Switching-Analysis/';
addpath(genpath(workingDir));
cd(sprintf('%s/Average-Predictive-Comparison/Standalone', workingDir));
make computeAPC_makefile
delete('run_computeAPCExec*.sh')
