% Queues average preditive comparison between rules at each level of
% another covariate for each time period and model run.
clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
numSim = 5000;
numSamples = 1000;
overwrite = true;

%% Pre-Test Stimulus
timePeriods = {'Intertrial Interval', 'Fixation', 'Rule Stimulus'};
model{1} = 'Rule * Rule Repetition + Rule * Previous Error History Indicator + Rule * Previous Congruency + Session Time';

for model_ind = 1:length(model)
    % Parse Model string for covariates
    parsedModelstr = strtrim(regexp(regexp(model{model_ind}, '+', 'split'), '*', 'split'));
    type = unique([parsedModelstr{:}]);
    fprintf('\n Model: %s\n', model{model_ind});
    for time_ind = 1:length(timePeriods),
        % Compute average predicitve comparson of rule at each level of the
        % interactions
        fprintf('\n\t Time Period: %s\n', timePeriods{time_ind});
        for type_ind = 1:length(type),
            fprintf('\t\t Covariate: %s\n', type{type_ind});
            computeAPC(model{model_ind}, timePeriods{time_ind}, main_dir, type{type_ind}, 'numSim', numSim, ...
                'numSamples', numSamples, 'overwrite', overwrite)
        end
    end
end

%% Post-Test Stimulus
timePeriods = {'Stimulus Response', 'Saccade', 'Reward'};
model{1} = 'Rule * Rule Repetition + Rule * Previous Error History Indicator + Rule * Congruency History + Previous Error History Indicator * Response Direction + Rule * Indicator Prep Time + Session Time';

for model_ind = 1:length(model)
    % Parse Model string for covariates
    parsedModelstr = strtrim(regexp(regexp(model{model_ind}, '+', 'split'), '*', 'split'));
    type = unique([parsedModelstr{:}]);
    fprintf('\n Model: %s\n', model{model_ind});
    for time_ind = 1:length(timePeriods),
        % Compute average predicitve comparson of rule at each level of the
        % interactions
        fprintf('\n\t Time Period: %s\n', timePeriods{time_ind});
        for type_ind = 1:length(type),
            fprintf('\t\t Covariate: %s\n', type{type_ind});
            computeAPC(model{model_ind}, timePeriods{time_ind}, main_dir, type{type_ind}, 'numSim', numSim, ...
                'numSamples', numSamples, 'overwrite', overwrite)
        end
    end
end