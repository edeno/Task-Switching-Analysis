clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
timePeriod = 'Rule Response';
% 
% acc_model = 'Rule * Switch + Rule * Congruency + Rule * Previous Error History + Response Direction + Normalized Prep Time';
% 
% GAMcluster(acc_model, timePeriod, main_dir, 'numFolds', 1, 'overwrite', true, 'ridgeLambda', .5);

acc_model = 'Rule * Switch History + Rule * Test Stimulus + Rule * Previous Error History + Normalized Prep Time';

GAMcluster(acc_model, timePeriod, main_dir, 'numFolds', 1, 'overwrite', true, 'ridgeLambda', .5);


%%
% timePeriod = 'Rule Stimulus';
% 
% acc_model = 'Rule * Switch + Rule * Previous Error History';
% 
% GAMcluster(acc_model, timePeriod, main_dir, 'numFolds', 1, 'overwrite', true, 'ridgeLambda', .5);

% timePeriod = 'Rule Stimulus';
% 
% acc_model = 'Rule * Switch History + Rule * Previous Error History';
% 
% GAMcluster(acc_model, timePeriod, main_dir, 'numFolds', 1, 'overwrite', true, 'ridgeLambda', .5);

timePeriod = 'Rule Stimulus';

acc_model = 'Rule Cues * Rule Cue Switch + Rule Cues * Previous Error History';

GAMcluster(acc_model, timePeriod, main_dir, 'numFolds', 1, 'overwrite', true, 'ridgeLambda', .5);
%%
% timePeriod = 'Stimulus Response';
% 
% % acc_model = 'Rule * Switch + Rule * Congruency + Rule * Previous Error History + Response Direction + Normalized Prep Time';
% acc_model = 'Rule * Switch + Rule * Test Stimulus + Rule * Previous Error History + Normalized Prep Time';
% 
% GAMcluster(acc_model, timePeriod, main_dir, 'numFolds', 1, 'overwrite', true, 'ridgeLambda', .5);
% 
% timePeriod = 'Stimulus Response';
% 
% acc_model = 'Rule * Switch + Rule * Congruency + Rule * Previous Error History + Response Direction + Normalized Prep Time';
% acc_model = 'Rule * Switch History + Rule * Test Stimulus + Rule * Previous Error History + Normalized Prep Time';
% 
% GAMcluster(acc_model, timePeriod, main_dir, 'numFolds', 1, 'overwrite', true, 'ridgeLambda', .5);




