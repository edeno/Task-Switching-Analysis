clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
ridgeLambda = 1;
numFolds = 1;
isOverwrite = false;

% %%
% timePeriod = 'Rule Stimulus';
% 
% % model{1} = 'Rule + Switch History + Previous Error History';
% % model{2} = 'Rule * Switch History + Rule * Previous Error History';
% % model{3} = 'Rule * Switch History + Rule * Previous Error History + Rule * Congruency History';
% model{1} = 'Rule * Switch History + Rule * Previous Error History + Rule * Congruency History';
% 
% for model_ind = 1:length(model)
%     
%     GAMcluster(model{model_ind}, timePeriod, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);
%     
% end
% 
% %%
% 
% timePeriod = 'Stimulus Response';runrun
% 
% model{1} = 'Rule * Switch History + Rule * Previous Error History + Rule * Test Stimulus + Normalized Prep Time';
% model{2} = 'Rule * Switch History + Rule * Previous Error History + Rule * Congruency History + Response Direction + Normalized Prep Time';
% 
% for model_ind = 1:length(model)
%     
%     GAMcluster(model{model_ind}, timePeriod, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);
%     
% end


%%
timePeriod = 'Rule Response';

% model{1} = 'Rule * Switch History + Rule * Previous Error History + Rule * Test Stimulus + Normalized Prep Time';
% model{1} = 'Rule * Switch History + Rule * Previous Error History + Rule * Congruency History + Response Direction + Normalized Prep Time';
model{1} = 'Rule * Switch History + Rule * Previous Error History + Rule * Congruency History + Response Direction + Rule * Normalized Prep Time';

for model_ind = 1:length(model)
    
    GAMcluster(model{model_ind}, timePeriod, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);
    
end

