function [neurons, gam, designMatrix] = ComputeGAMfit(timePeriod_dir, session_name, gamParams, save_dir)

%% Setup Save File
save_file_name = sprintf('%s/%s_GAMfit.mat', save_dir, session_name);

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
[designMatrix, gam] = gamModelMatrix(gamParams.regressionModel_str, GLMCov, spikes(:,1));

clear GLMCov;

if ~gamParams.includeIncorrect
    designMatrix(incorrect, :) = [];
    spikes(incorrect, :) = [];
    trial_time(incorrect) = [];
    trial_id(incorrect) = [];
    sample_on(incorrect) = [];
    percent_trials(incorrect) = [];
end

if ~gamParams.includeBeforeTimeZero,
    isBeforeZero = trial_time < 0;
    designMatrix(isBeforeZero, :) = [];
    spikes(isBeforeZero, :) = [];
    trial_time(isBeforeZero) = [];
    trial_id(isBeforeZero) = [];
    sample_on(isBeforeZero) = [];
    percent_trials(isBeforeZero) = [];
    
end

numTrials = length(unique(trial_id));
numPFC = sum(pfc);
numACC = sum(~pfc);

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

if ~flag
    fprintf('\nFitting GAMs ...\n');
    for curNeuron = 1:numNeurons,
        
        fprintf('\nNeuron %d \n', curNeuron);
        if numFolds > 1
            % Cross validate the model on each lambda and choose the best
            % one
            pred_error = nan(numFolds, numLambda);
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
                        'constraints', constraints, 'prior_weights', percent_trials(training_idx));
                    
                    edf_temp(curLambda, curFold) = fitInfo.edf;
                    
                    [stats] = gamStats(designMatrix(test_idx, :), spikes(test_idx, curNeuron), fitInfo, trial_id(test_idx),...
                        'Compact', true, 'prior_weights', percent_trials(test_idx));
                    
                    switch (gamParams.predType)
                        case 'AUC'
                            pred_error(curFold, curLambda) = stats.AUC_rescaled;
                        case 'Dev'
                            pred_error(curFold, curLambda) = stats.dev;
                        case 'MI'
                            pred_error(curFold, curLambda) = stats.mutual_information;
                        case 'AIC'
                            pred_error(curFold, curLambda) = stats.AIC;
                        case 'BIC'
                            pred_error(curFold, curLambda) = stats.BIC;
                        case 'GCV'
                            pred_error(curFold, curLambda) = stats.GCV;
                        case 'UBRE'
                            pred_error(curFold, curLambda) = stats.UBRE;
                    end
                    
                    
                end % End Lambda Loop
                
            end % End Fold Loop
            
            par_est_path{curNeuron} = par_est_path_temp(2:end, :, :);
            edf{curNeuron} = edf_temp;
            
            % Calculate mean prediction error
            mean_pred_error = mean(pred_error, 1);
            
            % Determine the best lambda
            switch (gamParams.predType)
                case {'AUC', 'MI'}
                    [~, bestLambda_ind] = max(mean_pred_error);
                case {'Dev', 'AIC', 'BIC', 'UBRE', 'GCV'}
                    [~, bestLambda_ind] = min(mean_pred_error);
            end
        else
            bestLambda_ind = 1;
        end
        
        lambda_vec = nan(size(constant_ind));
        lambda_vec(constant_ind) = ridgeLambda(bestLambda_ind);
        lambda_vec(~constant_ind) = smoothLambda(bestLambda_ind);
        lambda_vec(1) = 0;
        
        [neurons(curNeuron).par_est, fitInfo] = fitGAM(designMatrix, spikes(:, curNeuron), sqrtPen, ...
            'lambda', lambda_vec, 'distr', 'poisson', 'constant', const, ...
            'constraints', constraints, 'prior_weights', percent_trials);
        
        [neurons(curNeuron).stats] = gamStats(designMatrix, spikes(:, curNeuron), fitInfo, trial_id, ...
            'Compact', false, 'prior_weights', percent_trials);
        
    end % End Neuron Loop
end

%% Save to file
[~, hostname] = system('hostname');
hostname = strcat(hostname);
if strcmp(hostname, 'millerlab'),
    saveMillerlab('edeno', save_file_name, 'neurons', 'trial_id', ...
        'gam', 'trial_time', 'num*', 'gamParams', 'par_est_path', 'edf', 'designMatrix', ...
        '-v7.3');
else
    save(save_file_name, 'neurons', 'trial_id', ...
        'gam', 'trial_time', 'num*', 'gamParams', 'par_est_path', 'edf', 'designMatrix', ...
        '-v7.3');
end

end