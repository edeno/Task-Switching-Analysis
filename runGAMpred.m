%% ACC Models 
main_dir = '/data/home/edeno/Task Switching Analysis';
timePeriod = 'Rule Response';

% acc_model1 = 'Rule'; % Action/Task Set Selection: sensitive to task
% acc_model2 = 'Previous Error * Response Direction'; % Reinforcement Learning - change in reinforcement leads to change in response
% acc_model3 = 'Switch + Previous Error + Congruency'; % Conflict Monitoring - conflicts in representation lead to higher firing
% acc_model4 = 'Switch + Congruency + Previous Error * Response Direction'; %  Conflict Monitoring + Reinforcement Learning
% acc_model5 = 'Rule + Previous Error * Response Direction'; %  Action/Task Set Selection + Reinforcement Learning
% acc_model6 = 'Rule + Switch + Previous Error + Congruency'; %  Action/Task Set Selection + Conflict Monitoring
% acc_model7 = 'Rule + Switch + Congruency + Previous Error * Response Direction'; %  Action/Task Set Selection + Conflict Monitoring + Reinforcement Learning
% acc_model8 = 'Rule * Switch + Rule * Congruency + Rule * Previous Error + Previous Error * Response Direction'; % Rule Dependent Monitoring + Reinforcement Learning
% acc_model9 = 'Rule * Switch + Rule * Congruency + Rule * Previous Error'; % Rule Dependent Monitoring
% acc_model10 = 'Rule * Switch * Response Direction + Rule * Congruency * Response Direction + Rule * Previous Error * Response Direction'; % Predicted Response-Outcome 
% 
% acc_models = {acc_model1, acc_model2, acc_model3, acc_model4, acc_model7, acc_model8 };
% 
% for acc_ind = 1:length(acc_models),
%    
%     GAMcluster_pred(acc_models{acc_ind}, timePeriod, main_dir, 'numFolds', 10, 'overwrite', false);
%     
% end
% 
% 
% %% ACC Models with Prep Time
% timePeriod = 'Rule Response';
% 
% acc_model1N = 'Rule * Normalized Preparation Time';
% acc_model2N = 'Previous Error * Response Direction + Normalized Preparation Time';
% acc_model3N = 'Switch * Normalized Preparation Time + Previous Error * Normalized Preparation Time + Congruency * Normalized Preparation Time';
% 
% acc_model7Na = 'Rule + Switch + Congruency + Previous Error * Response Direction + Normalized Preparation Time';
% acc_model7Nb = 'Rule * Normalized Preparation Time + Switch * Normalized Preparation Time + Previous Error * Normalized Preparation Time + Congruency * Normalized Preparation Time + Previous Error * Response Direction';
% acc_model8N = 'Rule * Switch + Rule * Congruency + Rule * Previous Error + Rule * Normalized Preparation Time + Previous Error * Response Direction'; % Rule Dependent Monitoring + Reinforcement Learning
% 
% acc_modelsN = {acc_model1N, acc_model2N, acc_model3N, acc_model7Na, acc_model7Nb, acc_model8N};

%% DLPFC Models
timePeriod = 'Rule Response';

dlpfc_model1 = 'Rule Cues * Test Stimulus + Normalized Prep Time';
dlpfc_model2 = 'Rule * Test Stimulus + Normalized Prep Time';
dlpfc_model3 = 'Rule * Switch + Rule * Previous Error + Rule * Test Stimulus + Rule * Normalized Prep Time';
dlpfc_model4 = 'Rule * Switch + Rule * Test Stimulus + Rule * Previous Error + Rule * Normalized Prep Time + Test Stimulus * Normalized Prep Time';
dlpfc_model5 = 'Rule + Test Stimulus + Normalized Prep Time';
dlpfc_model6 = 'Rule Cues + Test Stimulus + Normalized Prep Time';
dlpfc_model7 = 'Rule * Normalized Prep Time';
dlpfc_model8 = 'Rule * Test Stimulus + Switch + Previous Error + Normalized Prep Time';

dlpfc_models = {dlpfc_model2, dlpfc_model3, dlpfc_model8};

for dlpfc_ind = 1:length(dlpfc_models),
   
    GAMcluster_pred(dlpfc_models{dlpfc_ind}, timePeriod, main_dir, 'numFolds', 10, 'overwrite', false);
    
end