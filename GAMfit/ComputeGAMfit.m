function [neurons, gam, designMatrix] = ComputeGAMfit(timePeriod_dir, session_name, gamParams, save_dir)

%% Setup Save File
if gamParams.isPrediction,
    save_file_name = sprintf('%s/%s_GAMpred.mat', save_dir, session_name);
else
    save_file_name = sprintf('%s/%s_GAMfit.mat', save_dir, session_name);
end

if exist(save_file_name, 'file') && ~gamParams.overwrite,
    designMatrix = [];
    gam = [];
    neurons = [];
    fprintf('File %s already exists. Skipping.\n', save_file_name);
    return;
end

%%  Load Data for Fitting
fprintf('\nLoading data...\n');
data_file_name = sprintf('%s/GLMCov/%s_GLMCov.mat', timePeriod_dir, session_name);
load(data_file_name);

% For some reason, matlab freaks out if you don't do this
wire_number = double(wire_number);
unit_number = double(unit_number);
pfc = double(pfc);

monkey_name = regexp(session_name, '(cc)|(isa)|(ch)', 'match');
monkey_name = monkey_name{:};

%% Setup Design Matrix
if all(gamParams.ridgeLambda == 0)
    referenceLevel = 'Reference';
else
    referenceLevel = 'Full';
end
[designMatrix, gam] = gamModelMatrix(gamParams.regressionModel_str, GLMCov, spikes(:,1), 'level_reference', referenceLevel);

clear GLMCov;

if ~gamParams.includeIncorrect
    designMatrix(~isCorrect, :) = [];
    spikes(~isCorrect, :) = [];
    trial_time(~isCorrect) = [];
    trial_id(~isCorrect) = [];
    sample_on(~isCorrect) = [];
    percent_trials(~isCorrect) = [];
    isAttempted(~isCorrect) = [];
end

if ~gamParams.includeTimeBeforeZero,
    isBeforeZero = trial_time < 0;
    designMatrix(isBeforeZero, :) = [];
    spikes(isBeforeZero, :) = [];
    trial_time(isBeforeZero) = [];
    trial_id(isBeforeZero) = [];
    sample_on(isBeforeZero) = [];
    percent_trials(isBeforeZero) = [];
    isAttempted(isBeforeZero) = [];
end

if ~gamParams.includeFixationBreaks
    designMatrix(~isAttempted, :) = [];
    spikes(~isAttempted, :) = [];
    trial_time(~isAttempted) = [];
    trial_id(~isAttempted) = [];
    sample_on(~isAttempted) = [];
    percent_trials(~isAttempted) = [];
end


numTrials = length(unique(trial_id));
numPFC = sum(pfc);
numACC = sum(~pfc);

% Number of trials for each level
trialIdByDesignMatrix = bsxfun(@times, designMatrix, ones(size(trial_id)));
trialIdByDesignMatrix = bsxfun(@times, trialIdByDesignMatrix, trial_id);
trialIdByDesignMatrix(trialIdByDesignMatrix == 0) = NaN;

for k = 1:size(designMatrix, 2),
    gam.numTrialsByLevel(k) = sum(~isnan(unique(trialIdByDesignMatrix(:, k))));
end

%% Do the fitting

% Make sure covariates and spikes are same size
flag = size(designMatrix, 1) ~= size(spikes, 1);

% Make sure covariates are of class double
designMatrix = double(designMatrix);

% Shut off constant default setting on GLM
const = 'off';

% Pre-allocate structure
neurons(numNeurons).par_est = [];
neurons(numNeurons).stats = [];

wire_number = num2cell(wire_number);
unit_number = num2cell(unit_number);
pfc = num2cell(pfc);

[neurons.wire_number] = deal(wire_number{:});
[neurons.unit_number] = deal(unit_number{:});
[neurons.file] = deal(session_name);
[neurons.pfc] = deal(pfc{:});
[neurons.monkey] = deal(monkey_name);

% Setup Cross Validation Folds
numParam = size(gam.constraints, 1);
numFolds = gamParams.numFolds;
ridgeLambda = gamParams.ridgeLambda;
smoothLambda = gamParams.smoothLambda;
numLambda = size(ridgeLambda, 2);
trials = unique(trial_id);
if numFolds > 1,
    CVO = cvpartition(length(trials), 'Kfold', numFolds);
else
    CVO = [];
end
par_est_path = cell(numNeurons, 1);
edf = cell(numNeurons, 1);
sqrtPen = gam.sqrtPen;
constraints = gam.constraints;
constant_ind = gam.constant_ind;
validPredType = {'Dev', 'AUC', 'MI', 'AIC', 'GCV', 'BIC', 'UBRE'};
numPredType = length(validPredType);
predInd = ismember(validPredType, gamParams.predType);
mean_pred_error = nan(1, numLambda, numPredType);

if ~flag
    fprintf('\nFitting GAMs ...\n');
    parfor curNeuron = 1:numNeurons,
        fprintf('\nNeuron %d \n', curNeuron);
        if numFolds > 1
            % Cross validate the model on each lambda and choose the best
            % one
            pred_error = nan(numFolds, numLambda, numPredType);
            par_est_path_temp = nan(numParam, numLambda, numFolds);
            edf_temp = nan(numLambda, numFolds);
            
            for curFold = 1:numFolds
                
                fprintf('\t Lambda Selection: Fold #%d\n', curFold);
                if numFolds > 1
                    training_idx = ismember(trial_id, trials(CVO.training(curFold)));
                    test_idx = ismember(trial_id, trials(CVO.test(curFold)));
                else
                    training_idx = true(size(designMatrix, 1), 1);
                    test_idx = true(size(designMatrix, 1), 1);
                end
                
                neurons(curNeuron).numSpikesPerFold(curFold) = sum(spikes(test_idx, curNeuron));
                
                % Fit the model on each lambda for each fold of the
                % cross validation
                for curLambda = 1:numLambda,
                    
                    fprintf('\t\t ... Lambda %d\n', curLambda);
                    lambda_vec = nan(size(constant_ind));
                    lambda_vec(constant_ind) = ridgeLambda(curLambda);
                    lambda_vec(~constant_ind) = smoothLambda(curLambda);
                    lambda_vec(1) = 0;
                    
                    [par_est_path_temp(:, curLambda, curFold), fitInfo] = fitGAM(designMatrix(training_idx, :), spikes(training_idx, curNeuron), sqrtPen, ...
                        'lambda', lambda_vec, 'distr', 'poisson', 'constant', const, ...
                        'constraints', constraints);
                    
                    edf_temp(curLambda, curFold) = fitInfo.edf;
                    
                    [stats] = gamStats(designMatrix(test_idx, :), spikes(test_idx, curNeuron), fitInfo, trial_id(test_idx),...
                        'Compact', true);
                    
                    % Store different types of prediction error for each
                    % fold and lambda
                    pred_error(curFold, curLambda, 1) = stats.dev;
                    pred_error(curFold, curLambda, 2) = stats.AUC_rescaled;
                    pred_error(curFold, curLambda, 3) = stats.mutual_information;
                    
                end % End Lambda Loop
                
            end % End Fold Loop
            
            par_est_path{curNeuron} = par_est_path_temp(2:end, :, :);
            edf{curNeuron} = edf_temp;
            
            % Calculate mean prediction error for best fit model
            mean_pred_error = mean(pred_error, 1);
            
            % Determine the best lambda for best fit model
            switch (gamParams.predType)
                case {'AUC', 'MI'}
                    [~, bestLambda_ind] = max(mean_pred_error(:, :, predInd));
                case 'Dev'
                    [~, bestLambda_ind] = min(mean_pred_error(:, :, predInd));
            end
        else
            bestLambda_ind = 1;
            neurons(curNeuron).numSpikesPerFold(1) = sum(spikes(:, curNeuron));
            if gamParams.isPrediction,
                lambda_vec = nan(size(constant_ind));
                lambda_vec(constant_ind) = ridgeLambda(bestLambda_ind);
                lambda_vec(~constant_ind) = smoothLambda(bestLambda_ind);
                lambda_vec(1) = 0;
                
                [neurons(curNeuron).par_est, fitInfo] = fitGAM(designMatrix, spikes(:, curNeuron), sqrtPen, ...
                    'lambda', lambda_vec, 'distr', 'poisson', 'constant', const, ...
                    'constraints', constraints);
                
                [neurons(curNeuron).stats] = gamStats(designMatrix, spikes(:, curNeuron), fitInfo, trial_id, ...
                    'Compact', false);
                
            end
            
        end % End Number of Folds
        
        lambda_vec = nan(size(constant_ind));
        lambda_vec(constant_ind) = ridgeLambda(bestLambda_ind);
        lambda_vec(~constant_ind) = smoothLambda(bestLambda_ind);
        lambda_vec(1) = 0;
        
        [neurons(curNeuron).par_est, fitInfo] = fitGAM(designMatrix, spikes(:, curNeuron), sqrtPen, ...
            'lambda', lambda_vec, 'distr', 'poisson', 'constant', const, ...
            'constraints', constraints);
        
        stats = gamStats(designMatrix, spikes(:, curNeuron), fitInfo, trial_id, ...
            'Compact', false);
        
        neurons(curNeuron).stats = stats;
        pred_error(:, :, 4) = stats.AIC;
        pred_error(:, :, 5) = stats.GCV;
        pred_error(:, :, 6) = stats.BIC;
        pred_error(:, :, 7) = stats.UBRE;
        
        neurons(curNeuron).pred_error = pred_error;
        
    end % End Neuron Loop
end

%% Save to file
[~, hostname] = system('hostname');
hostname = strtrim(hostname);
if strcmp(hostname, 'millerlab'),
    saveMillerlab('edeno', save_file_name, 'neurons', 'trial_id', ...
        'gam', 'trial_time', 'num*', 'gamParams', 'par_est_path', 'edf', ...
        'designMatrix', 'validPredType', 'CVO', '-v7.3');
else
    save(save_file_name, 'neurons', 'trial_id', ...
        'gam', 'trial_time', 'num*', 'gamParams', 'par_est_path', 'edf', ...
        'designMatrix', 'validPredType',  'CVO', '-v7.3');
end

end