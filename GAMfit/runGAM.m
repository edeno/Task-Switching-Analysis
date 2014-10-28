clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
ridgeLambda = 1;
numFolds = 1;
isOverwrite = true;

%% Pre-Test Stimulus
timePeriods = {'Intertrial Interval', 'Fixation', 'Rule Stimulus'};
model{1} = 'Rule * Switch History + Rule * Previous Error + Rule * Previous Congruency';

for time_ind = 1:length(timePeriods),
    for model_ind = 1:length(model)
        
        GAMcluster(model{model_ind}, timePeriods{time_ind}, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);
        
    end
end

%% Post-Test Stimulus
timePeriods = {'Stimulus Response', 'Saccade', 'Reward', 'Rule Response'};
model{1} = 'Rule * Switch History + Rule * Previous Error + Rule * Congruency History + Previous Error * Response Direction + Rule * Normalized Prep Time';

for time_ind = 1:length(timePeriods),
    for model_ind = 1:length(model)
        
        GAMcluster(model{model_ind}, timePeriods{time_ind}, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);
        
    end
end

