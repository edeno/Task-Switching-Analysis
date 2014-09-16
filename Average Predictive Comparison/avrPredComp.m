% This function computes the average predictive comparison between rules at
% a particular level of another covariate (the "by" variable).
% For example, we could compute the average difference between rules when
% an error has been committed in the previous trial or when the monkey
% saccades to the left.
function [avpred] = avrPredComp(session_name, timePeriod, model_name, factor_name, numSim, numSamples, save_folder, main_dir)

% Load covariate fit and model fit information
load([main_dir, '/paramSet.mat'], 'cov_info', 'data_info');
GLMCov_name = sprintf('%s/%s/GLMCov/%s_GLMCov.mat', data_info.processed_dir, timePeriod, session_name);
load(GLMCov_name, 'GLMCov', 'incorrect', 'spikes')
GAMfit_name = sprintf('%s/%s/Models/%s/%s_GAMfit.mat', data_info.processed_dir, timePeriod, model_name, session_name);
load(GAMfit_name, 'gam', 'gamParams', 'neurons', 'designMatrix', 'numNeurons');

% Get the names of the covariates for the current model
cov_names = strtrim(regexp(regexp(gam.model_str, '+', 'split'), '*', 'split'));
unique_cov_names = unique([cov_names{:}]);

% Size of Design Matrix
[numData, numPredictors] = size(designMatrix);

% Simulate from posterior
par_est = nan(numPredictors, numNeurons, numSim);

for neuron_ind = 1:numNeurons,
    par_est(:, neuron_ind, :) = mvnrnd(neurons(neuron_ind).par_est, neurons(neuron_ind).stats.covb, numSim)';
end

% Cut down on the number of data points by sampling
if numData == numSamples,
    sample_ind = 1:numData;
else
    sample_ind = randi([1, numData], [1 numSamples]);
    numData = numSamples;
end

% Find the covariate index for the current variable, the variable to be held
% constant and the other inputs
factor_ind = ismember({GLMCov.name}, factor_name);
other_ind = ismember({GLMCov.name}, unique_cov_names) & (~factor_ind);

factor_data = GLMCov(factor_ind).data;
other_data = {GLMCov(other_ind).data};

isCategorical = [GLMCov(other_ind).isCategorical] & ~ismember({GLMCov(other_ind).name}, {'Switch History', 'Previous Error History Indicator'});

other_data(isCategorical) = cellfun(@(x) dummyvar(x), other_data(isCategorical), 'UniformOutput', false);

isCategorical = cellfun(@(categorical, data) repmat(categorical, [1 size(data,2)]), num2cell(isCategorical), other_data, 'UniformOutput', false);

% If Incorrect trials were removed in the original fit, do so again
if ~gamParams.includeIncorrect
    factor_data = factor_data(~incorrect, :);
    other_data = cellfun(@(x) x(~incorrect, :), other_data, 'UniformOutput', false);
end

numFactors = size(factor_data, 2);

% If the factor is a history variable, then we need to loop over each
% history variable. If the factor is an ordered categorical variable with
% more than two levels, we need to calculate the different between all the
% other levels and the last level. Currently no support for unordered
% categorical variables that aren't binary.
counter_idx = 1;

for factor_id = 1:numFactors,
    
    %% Figure out the matrix of other inputs
    if any(ismember({'Previous Error History', 'Congruency History'}, factor_name)),
        history = factor_data(:, find(~ismember(1:numFactors, factor_id)));
        history = dummyvar(history);
    else
        history = [];
    end
    
    other_inputs = [other_data{:} history];
    other_inputs = other_inputs(sample_ind, :);
    %% Compute covariance matrix used for Mahalanobis distances:
    % Find weights
    other_isCategorical = [isCategorical{:} true(1, size(history ,2))];
    [summed_weights] = apc_weights(other_inputs, other_isCategorical);
    %% Compute the difference the lowest level and all other levels (doesn't work for unordered categorical variables)
    if GLMCov(factor_ind).isCategorical,
        level_data = unique(factor_data(:, ismember(factor_id, 1:numFactors)));
        level_data(isnan(level_data)) = [];
    else
        level_data = [-1 1];
    end
    % Number of levels to iterate over. Comparing to the last level so
    % subtracting one.
    numLevels = length(level_data) - 1;
    
    % Compute the firing rate holding thne last level constant (only need to do this once)
    lastLevelCov = GLMCov;
    lastLevelCov(factor_ind).data(:, factor_id) = level_data(end);
    [lastLevel_design] = gamModelMatrix(gamParams.regressionModel_str, lastLevelCov, spikes(:,1));
    if ~gamParams.includeIncorrect
        lastLevel_design = lastLevel_design(~incorrect, :);
    end
    lastLevel_design = lastLevel_design(sample_ind, :);
    lastLevel_est = nan(numData, numNeurons, numSim);
    for neuron_ind = 1:numNeurons,
        lastLevel_est(:, neuron_ind, :) = exp(lastLevel_design*squeeze(par_est(:, neuron_ind, :)))*1000;
    end

    for level_id = 1:numLevels,
        curLevelCov = GLMCov;
        curLevelCov(factor_ind).data(:, factor_id) = level_data(level_id);
        [curLevel_design] = gamModelMatrix(gamParams.regressionModel_str, curLevelCov, spikes(:,1));
        if ~gamParams.includeIncorrect
            curLevel_design = curLevel_design(~incorrect, :);
        end
        curLevel_design = curLevel_design(sample_ind, :);
        
        curLevel_est = nan(numData, numNeurons, numSim);
        for neuron_ind = 1:numNeurons,
            curLevel_est(:, neuron_ind, :) = exp(curLevel_design*squeeze(par_est(:, neuron_ind, :)))*1000;
        end
        
        diff_est = curLevel_est - lastLevel_est;
        
        num = nansum(bsxfun(@times, summed_weights, diff_est));
        abs_num = nansum(bsxfun(@times, summed_weights, abs(diff_est)));
        rms_num = nansum(bsxfun(@times, summed_weights, diff_est.^2));
        
        den = nansum(summed_weights);
        
        apc = squeeze(num./den);
        abs_apc = squeeze(abs_num./den);
        rms_apc = squeeze(sqrt(rms_num)./den);
        
        for neuron_ind = 1:numNeurons,
            avpred(neuron_ind).apc(counter_idx,:) = apc(neuron_ind, :);
            avpred(neuron_ind).abs_apc(counter_idx,:) = abs_apc(neuron_ind, :);
            avpred(neuron_ind).rms_apc(counter_idx,:) = rms_apc(neuron_ind, :);
        end
        counter_idx = counter_idx + 1;
    end
    
end

[avpred.numSamples] = deal(numSamples);
[avpred.numSim] = deal(numSim);
[avpred.session_name] = deal(session_name);
[avpred.model_name] = deal(model_name);
[avpred.wire_number] = deal(neurons.wire_number);
[avpred.unit_number] = deal(neurons.unit_number);
[avpred.pfc] = deal(neurons.pfc);
[avpred.monkey] = deal(neurons.monkey);
baseline = num2cell(mean(exp(par_est(1, :, :))*1000, 3));
[avpred.baseline_firing] = deal(baseline{:});

save_file_name = sprintf('%s/%s_APC.mat', save_folder, session_name);
saveMillerlab('edeno', save_file_name, 'avpred');

end