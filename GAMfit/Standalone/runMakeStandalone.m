%% Compiles the standalone
workingDir = '/projectnb/pfc-rule/Task-Switching-Analysis/';
addpath(genpath(workingDir));
cd(sprintf('%s/GAMfit/Standalone', workingDir));
make GAMCluster_makefile
delete('run_GAMClusterExec*.sh')