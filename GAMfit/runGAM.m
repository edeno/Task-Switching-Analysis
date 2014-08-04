clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
ridgeLambda = 1;
numFolds = 1;
isOverwrite = true;

%%
timePeriods = {'Rule Response', 'Stimulus Response'};

model{1} = 'Rule * Switch History + Rule * Previous Error History + Rule * Congruency History + Response Direction + Rule * Normalized Prep Time';
model{2} = 'Rule * Switch History + Rule * Previous Error History Indicator + Rule * Congruency History + Response Direction + Rule * Normalized Prep Time';

for time_ind = 1:length(timePeriods),
    for model_ind = 1:length(model)
        
        GAMcluster(model{model_ind}, timePeriods{time_ind}, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);
        
    end
end

%%
timePeriods = {'Intertrial Interval', 'Fixation', 'Rule Stimulus', 'Saccade', 'Reward'};

model{1} = 'Rule * Switch History + Rule * Previous Error History + Rule * Previous Congruency';
model{2} = 'Rule * Switch History + Rule * Previous Error History Indicator + Rule * Previous Congruency';

for time_ind = 1:length(timePeriods),
    for model_ind = 1:length(model)
        
        GAMcluster(model{model_ind}, timePeriods{time_ind}, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);
        
    end
end