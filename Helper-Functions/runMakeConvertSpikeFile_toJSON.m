%% Compiles the standalone
workingDir = '/projectnb/pfc-rule/Task-Switching-Analysis/';
addpath(genpath(workingDir));
cd(sprintf('%s/Helper-Functions/Standalone', workingDir));
make convertSpikeFile_toJSON_makefile
delete('run_computeConvertSpikeFileExec*.sh')
