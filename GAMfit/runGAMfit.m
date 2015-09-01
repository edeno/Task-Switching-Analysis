clear all; close all; clc;
setMainDir;
main_dir = getenv('MAIN_DIR');
ridgeLambda = 0;
numFolds = 1;
isOverwrite = true;

%% Pre-Test Stimulus
timePeriods = {'Intertrial Interval', 'Fixation', 'Rule Stimulus'};
covariates = {'Rule', 'Rule Repetition', 'Previous Error History', 'Previous Congruency'};
ruleInteractionCovariates = {'Rule * Rule Repetition', 'Rule * Previous Error History', 'Rule * Previous Congruency'};
model = unique([createModelCollection(covariates) createModelCollection(ruleInteractionCovariates)], 'stable');

for time_ind = 1:length(timePeriods),
    fprintf('\n\t Time Period: %s\n', timePeriods{time_ind});
    for model_ind = 1:length(model)
        fprintf('\n Model: %s\n', model{model_ind});
        GAMcluster(model{model_ind}, timePeriods{time_ind}, main_dir, 'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda);        
    end
end

%% Post-Test Stimulus
timePeriods = {'Stimulus Response', 'Saccade', 'Reward'};
covariates = {'Rule', 'Rule Repetition', 'Congruency History', 'Previous Error History', 'Response Direction', 'Indicator Prep Time'};
ruleInteractionCovariates = {'Rule * Rule Repetition', 'Rule * Congruency History', 'Rule * Previous Error History', 'Rule * Response Direction', 'Rule * Indicator Prep Time'};
model = unique([createModelCollection(covariates) createModelCollection(ruleInteractionCovariates)], 'stable');

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
