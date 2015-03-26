clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
ridgeLambda = 10.^(-1:3);
numFolds = 5;
isOverwrite = true;

%% Pre-Test Stimulus
timePeriods = {'Intertrial Interval', 'Fixation', 'Rule Stimulus'};

% All Interactions
model{1} = 'Rule + Rule Repetition + Previous Error + Previous Congruency';
model{2} = 'Rule * Rule Repetition + Rule * Previous Error + Rule * Previous Congruency';

for time_ind = 1:length(timePeriods),
    fprintf('\n\t Time Period: %s\n', timePeriods{time_ind});
    for model_ind = 1:length(model)
        fprintf('\n Model: %s\n', model{model_ind});
        GAMcluster(model{model_ind}, timePeriods{time_ind}, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);        
    end
end

%% Post-Test Stimulus
timePeriods = {'Stimulus Response', 'Saccade', 'Reward'};
model{1} = 'Rule + Rule Repetition + Congruency History + Previous Error * Response Direction + Indicator Prep Time';
model{2} = 'Rule * Rule Repetition + Rule * Previous Error + Rule * Congruency History + Previous Error * Response Direction + Rule * Indicator Prep Time';

for time_ind = 1:length(timePeriods),
    fprintf('\n\t Time Period: %s\n', timePeriods{time_ind});
    for model_ind = 1:length(model)
        fprintf('\n Model: %s\n', model{model_ind});
        GAMcluster(model{model_ind}, timePeriods{time_ind}, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);        
    end
end

%% Post-Test Stimulus - over time
% timePeriods = {'Stimulus Response'};
% model{1} = 's(Rule, Trial Time) + s(Rule Repetition, Trial Time) + s(Previous Error, Trial Time) + s(Congruency History, Trial Time) + s(Response Direction, Trial Time) + s(Indicator Prep Time, Trial Time)';
% model{2} = 'Rule * Rule Repetition + Rule * Previous Error + Rule * Congruency History + Previous Error * Response Direction + Rule * Indicator Prep Time';
% 
% for time_ind = 1:length(timePeriods),
%     fprintf('\n\t Time Period: %s\n', timePeriods{time_ind});
%     for model_ind = 1:length(model)
%         fprintf('\n Model: %s\n', model{model_ind});
%         GAMcluster(model{model_ind}, timePeriods{time_ind}, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, 'includeTimeBeforeZero', true);        
%     end
% end
