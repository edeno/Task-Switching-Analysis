% Queues average preditive comparison between rules at each level of
% another covariate for each time period and model run.
clear all; close all; clc;
main_dir = '/data/home/edeno/Task Switching Analysis';
numSim = 1000;
numSamples = 1000;
overwrite = true;

%%
timePeriods = {'Rule Response', 'Stimulus Response'};

model{1} = 'Rule * Switch History + Rule * Previous Error History + Rule * Congruency History + Response Direction + Rule * Normalized Prep Time';
model{2} = 'Rule * Switch History + Rule * Previous Error History Indicator + Rule * Congruency History + Response Direction + Rule * Normalized Prep Time';

for time_ind = 1:length(timePeriods),
    for model_ind = 1:length(model)
        % Parse Model string for rule interactions
        parsedModelstr = strtrim(regexp(regexp(model{model_ind}, '+', 'split'), '*', 'split'));
        isRuleInteraction = cellfun(@(x) ismember('Rule', x), parsedModelstr);
        parsedModelstr = parsedModelstr(isRuleInteraction);
        type = cellfun(@(x) x{~ismember(x, 'Rule')}, parsedModelstr, 'UniformOutput', false);
        % Compute average predicitve comparson of rule at each level of the
        % interactions
        for type_ind = 1:length(type),
            computeRuleByAPC(model{model_ind}, timePeriods{time_ind}, main_dir, type{type_ind}, 'numSim', numSim, ...
                'numSamples', numSamples, 'overwrite', overwrite)
        end        
    end
end
%%
timePeriods = {'Intertrial Interval', 'Fixation', 'Rule Stimulus', 'Saccade', 'Reward'};

model{1} = 'Rule * Switch History + Rule * Previous Error History + Rule * Previous Congruency';
model{2} = 'Rule * Switch History + Rule * Previous Error History Indicator + Rule * Previous Congruency';

for time_ind = 1:length(timePeriods),
    for model_ind = 1:length(model)
        % Parse Model string for rule interactions
        parsedModelstr = strtrim(regexp(regexp(model{model_ind}, '+', 'split'), '*', 'split'));
        isRuleInteraction = cellfun(@(x) ismember('Rule', x), parsedModelstr);
        parsedModelstr = parsedModelstr(isRuleInteraction);
        type = cellfun(@(x) x{~ismember(x, 'Rule')}, parsedModelstr, 'UniformOutput', false);
        % Compute average predicitve comparson of rule at each level of the
        % interactions
        for type_ind = 1:length(type),
            computeRuleByAPC(model{model_ind}, timePeriods{time_ind}, main_dir, type{type_ind}, 'numSim', numSim, ...
                'numSamples', numSamples, 'overwrite', overwrite)
        end        
    end
end
