%% DLPFC

% main_dir = '/data/home/edeno/Task Switching Analysis';
% timePeriod = 'Rule Response';
% 
% dlpfc_model3 = 'Rule * Switch + Rule * Previous Error + Rule * Test Stimulus + Rule * Normalized Prep Time';
% 
% GAMcluster(dlpfc_model3, timePeriod, main_dir, 'numFolds', 10, 'overwrite', false);

%% ACC Models
main_dir = '/data/home/edeno/Task Switching Analysis';
timePeriod = 'Rule Response';

% acc_model8 = 'Rule * Switch + Rule * Congruency + Rule * Previous Error + Previous Error * Response Direction'; % Rule Dependent Monitoring + Reinforcement Learning
acc_model = 'Rule + Switch + Congruency + Previous Error * Response Direction';

GAMcluster(acc_model, timePeriod, main_dir, 'numFolds', 10, 'overwrite', false);


