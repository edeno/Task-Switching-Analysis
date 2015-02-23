clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
ridgeLambda = 1;
numFolds = 1;
isOverwrite = true;

%% Pre-Test Stimulus
timePeriods = {'Intertrial Interval', 'Fixation', 'Rule Stimulus'};
model{1} = 'Rule * Rule Repetition + Rule * Previous Error + Rule * Previous Congruency + Session Time';

for time_ind = 1:length(timePeriods),
    for model_ind = 1:length(model)
        
        GAMcluster(model{model_ind}, timePeriods{time_ind}, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);
        
    end
end

%% Post-Test Stimulus
timePeriods = {'Stimulus Response', 'Saccade', 'Reward'};
model{1} = 'Rule * Rule Repetition + Rule * Previous Error + Rule * Congruency History + Previous Error * Response Direction + Rule * Indicator Prep Time + Session Time';

for time_ind = 1:length(timePeriods),
    for model_ind = 1:length(model)
        
        GAMcluster(model{model_ind}, timePeriods{time_ind}, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);
        
    end
end

