clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
ridgeLambda = 10;
numFolds = 1;
isOverwrite = true;

%% Pre-Test Stimulus
timePeriods = {'Intertrial Interval', 'Fixation', 'Rule Stimulus'};

% All Interactions
model{1} = 'Rule * Rule Repetition + Rule * Previous Error + Rule * Previous Congruency + Session Time';
% % All Interactions w/o Congruency
% model{2} = 'Rule * Rule Repetition + Rule * Previous Error + Session Time';
% % All Interactions w/o Congruency, Previous Error
% model{3} = 'Rule * Rule Repetition + Session Time';
% % All Interactions w/o Congruency, Repetitions
% model{4} = 'Rule * Previous Error + Session Time';
% % No Interactions w/o Congruency
% model{5} = 'Rule + Rule Repetition + Previous Error + Session Time';
% % No Interactions w/o Congruency, Repetitions
% model{6} = 'Rule + Previous Error + Session Time';
% % No Interactions w/o Congruency, Previous Error History
% model{7} = 'Rule + Rule Repetition + Session Time';
% % No Interactions w/o Congruency, Rule
% model{8} = 'Rule Repetition + Previous Error + Session Time';
% % No Interactions w/o Congruency, Rule, Rule Repetition
% model{8} = 'Previous Error + Session Time';
% % No Interactions w/o Congruency, Rule Repetition, Previous Error History
% model{9} = 'Rule + Session Time';

for time_ind = 1:length(timePeriods),
    fprintf('\n\t Time Period: %s\n', timePeriods{time_ind});
    for model_ind = 1:length(model)
        fprintf('\n Model: %s\n', model{model_ind});
        GAMcluster(model{model_ind}, timePeriods{time_ind}, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);        
    end
end

%% Post-Test Stimulus
timePeriods = {'Stimulus Response', 'Saccade', 'Reward'};
model{1} = 'Rule * Rule Repetition + Rule * Previous Error + Rule * Congruency History + Previous Error * Response Direction + Rule * Indicator Prep Time + Session Time';

for time_ind = 1:length(timePeriods),
    fprintf('\n\t Time Period: %s\n', timePeriods{time_ind});
    for model_ind = 1:length(model)
        fprintf('\n Model: %s\n', model{model_ind});
        GAMcluster(model{model_ind}, timePeriods{time_ind}, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);        
    end
end