%% Compiles the standalone
workingDir = '/projectnb/pfc-rule/Task-Switching-Analysis/';
addpath(genpath(workingDir));
cd(sprintf('%s/Permutation-Analysis/Standalone', workingDir));
make computeRuleByPermutationAnalysis_makefile
delete('run_computeRuleByPermutationAnalysisExec*.sh')
