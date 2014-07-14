%% DLPFC

main_dir = '/data/home/edeno/Task Switching Analysis';
timePeriod = 'Rule Response';

% dlpfc_model3 = 'Rule * Switch + Rule * Previous Error + Rule * Test Stimulus + Rule * Normalized Prep Time';
dlpfc_model = 'Rule + Switch + Previous Error + Test Stimulus + Response Direction';

GAMcluster(dlpfc_model, timePeriod, main_dir, 'numFolds', 1, 'overwrite', true, 'lambda', .5);

dlpfc_model = 'Rule + Switch + Previous Error + Test Stimulus + Response Direction + Normalized Prep Time';

GAMcluster(dlpfc_model, timePeriod, main_dir, 'numFolds', 1, 'overwrite', true, 'lambda', .5);


%% ACC Models
% main_dir = '/data/home/edeno/Task Switching Analysis';
% timePeriod = 'Rule Response';
% 
% % acc_model8 = 'Rule * Switch + Rule * Congruency + Rule * Previous Error + Previous Error * Response Direction'; % Rule Dependent Monitoring + Reinforcement Learning
% acc_model = 'Rule + Switch + Congruency + Previous Error * Response Direction';

acc_model = 'Rule + Switch + Congruency + Previous Error * Response Direction + Normalized Prep Time';

GAMcluster(acc_model, timePeriod, main_dir, 'numFolds', 1, 'overwrite', true, 'lambda', .5);


