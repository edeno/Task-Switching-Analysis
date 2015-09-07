%% Simulate effect of number of trials and difference of firing rate on MI and AUC
clear all; close all; clc;

% GAMpred parameters
ridgeLambda = 0;
numFolds = 5;
isOverwrite = true;

% Simulate Session
numTrials = 500:1000:3500;
orientRate = 1.1:0.2:3;
colorRate = 1;
numSamples = 5;

AUC = nan(numSamples, length(numTrials), length(orientRate));
MI = nan(numSamples, length(numTrials), length(orientRate));
ruleRatio = nan(numSamples, length(numTrials), length(orientRate));

for sample_ind = 1:numSamples,
    fprintf('\nSample #%d \n', sample_ind);
    for trials_ind = 1:length(numTrials),
        fprintf('\n Number of Trials:  %d \n', numTrials(trials_ind));
        for ratio_ind = 1:length(orientRate),
            fprintf('\n Ratio:  %d \n', orientRate(ratio_ind));
            [GLMCov, trial_time] = simSession(numTrials(trials_ind));
            
            %% Binary Categorical Covariate - Rule
            Rate = nan(size(trial_time));
            
            cov_ind = @(cov_name) ismember({GLMCov.name}, cov_name);
            cov_id = @(cov_name, level_name) find(ismember(GLMCov(cov_ind(cov_name)).levels, level_name));
            level_ind = @(cov_name, level_name) ismember(GLMCov(cov_ind(cov_name)).data, cov_id(cov_name, level_name));
            
            
            Rate(level_ind('Rule', 'Color')) = colorRate;
            Rate(level_ind('Rule', 'Orientation')) = orientRate(ratio_ind);
            
            % Correct Model
            model = 'Rule';
            [neurons, gam, designMatrix, spikes, model_dir] = testComputeGAMfit_wrapper(model, Rate, ...
                'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, ...
                'isPrediction', true);
            
            % Misspecified Model
            model = 'Response Direction';
            [neurons_misspecified, gam_misspecified, designMatrix_misspecified, spikes_misspecified, model_dir] = testComputeGAMfit_wrapper(model, Rate, ...
                'numFolds', numFolds, 'overwrite', isOverwrite, 'ridgeLambda', ridgeLambda, ...
                'isPrediction', true, 'spikes', spikes);
            
            AUC(sample_ind, trials_ind, ratio_ind) = neurons.stats.AUC - neurons_misspecified.stats.AUC;
            MI(sample_ind, trials_ind, ratio_ind) = neurons.stats.mutual_information - neurons_misspecified.stats.mutual_information;
            
            ruleRatio(sample_ind, trials_ind, ratio_ind) = orientRate(ratio_ind) / colorRate;
            
        end
    end
end

save('sensitivityAnalysis.mat', 'AUC', 'MI', 'ruleRatio', 'numSamples', ...
    'numTrials', 'orientRate', 'colorRate', 'numFolds', 'ridgeLambda')
%% Plot