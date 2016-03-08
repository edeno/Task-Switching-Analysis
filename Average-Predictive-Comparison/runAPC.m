% Queues average preditive comparison between rules at each level of
% another covariate for each time period and model run.

for model_ind = 1:length(model)
    % Parse Model string for covariates
    parsedModel = modelFormulaParse(model{model_ind});
    type = unique(parsedModel.terms);
    fprintf('\n Model: %s\n', model{model_ind});
    for time_ind = 1:length(timePeriods),
        % Compute average predicitve comparson of rule at each level of the
        % interactions
        fprintf('\n\t Time Period: %s\n', timePeriods{time_ind});
        for type_ind = 1:length(type),
            fprintf('\t\t Covariate: %s\n', type{type_ind});
            computeAPC(model{model_ind}, timePeriods{time_ind}, type{type_ind}, ...
                'numSim', numSim, ...
                'numSamples', numSamples, ...
                'overwrite', overwrite, ...
                'walltime', walltime, ...
                'mem', mem, ...
                'numCores', numCores);
        end
    end
end
