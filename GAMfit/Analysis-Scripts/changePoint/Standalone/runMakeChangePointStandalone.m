%% Compiles the standalone
workingDir = '/projectnb/pfc-rule/Task-Switching-Analysis/';
addpath(genpath(workingDir));
cd(sprintf('%s/GAMfit/Analysis-Scripts/changePoint/Standalone', workingDir));
make changePoint_makefile
delete('run_changePointExec*.sh')