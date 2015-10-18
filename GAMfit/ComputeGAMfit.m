function [neurons, stats, gam, designMatrix, modelList, gamParams] = ComputeGAMfit(sessionName, gamParams)
%% Log parameters
fprintf('\n------------------------\n');
fprintf('\nSession: %s\n', sessionName);
fprintf('\nDate: %s\n \n', datestr(now));
fprintf('\nGAM Parameters\n');
fprintf('\t regressionModel_str: %s\n', gamParams.regressionModel_str);
fprintf('\t timePeriod: %s\n', gamParams.timePeriod);
fprintf('\t numFolds: %d\n', gamParams.numFolds);
fprintf('\t ridgeLambda: %d\n', gamParams.ridgeLambda);
fprintf('\t smoothLambda: %d\n', gamParams.smoothLambda);
fprintf('\t overwrite: %d\n', gamParams.overwrite);
fprintf('\t includeIncorrect: %d\n', gamParams.includeIncorrect);
fprintf('\t includeTimeBeforeZero: %d\n', gamParams.includeTimeBeforeZero);
fprintf('\t isPrediction: %d\n', gamParams.isPrediction);
%% Get directories
main_dir = getWorkingDir();
timePeriod_dir = sprintf('%s/Processed Data/%s/', main_dir, gamParams.timePeriod);
%% Create Model Directory
model_dir = sprintf('%s/Models/', timePeriod_dir);

if ~exist(model_dir, 'dir'),
    mkdir(model_dir);
end

if exist(sprintf('%s/Models/modelList.mat', timePeriod_dir), 'file'),
    load(sprintf('%s/Models/modelList.mat', timePeriod_dir), 'modelList');
    if ~modelList.isKey(gamParams.regressionModel_str)
        modelList(gamParams.regressionModel_str) = sprintf('M%d', modelList.length + 1);
    end
else
    modelList = containers.Map(gamParams.regressionModel_str, 'M1');
end
save(sprintf('%s/Models/modelList.mat', timePeriod_dir), 'modelList');

save_dir = sprintf('%s/Models/%s', timePeriod_dir, modelList(gamParams.regressionModel_str));

if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end

%% Setup Save File
if gamParams.isPrediction,
    saveFileName = sprintf('%s/%s_GAMpred.mat', save_dir, sessionName);
else
    saveFileName = sprintf('%s/%s_GAMfit.mat', save_dir, sessionName);
end

if exist(saveFileName, 'file') && ~gamParams.overwrite,
    designMatrix = [];
    gam = [];
    neurons = [];
    fprintf('File %s already exists. Skipping.\n', saveFileName);
    return;
end

%%  Load Data for Fitting
fprintf('\nLoading data...\n');
data_file_name = sprintf('%s/GLMCov/%s_GLMCov.mat', timePeriod_dir, sessionName);
load(data_file_name);

% For some reason, matlab freaks out if you don't do this
wire_number = double(wire_number);
unit_number = double(unit_number);
pfc = logical(pfc);

monkey_name = regexp(sessionName, '(cc)|(isa)|(ch)|(test)', 'match');
monkey_name = monkey_name{:};

%% Setup Design Matrix
fprintf('\nConstructing model design matrix...\n');
if all(gamParams.ridgeLambda == 0)
    referenceLevel = 'Reference';
else
    referenceLevel = 'Full';
end

if ~gamParams.includeIncorrect
    for cov_ind = 1:length(GLMCov),
        if isempty(GLMCov(cov_ind).data), continue; end;
        GLMCov(cov_ind).data(~isCorrect, :) = [];
    end
    spikes(~isCorrect, :) = [];
    trial_time(~isCorrect) = [];
    trial_id(~isCorrect) = [];
    sample_on(~isCorrect) = [];
    percent_trials(~isCorrect) = [];
    isAttempted(~isCorrect) = [];
end

if ~gamParams.includeTimeBeforeZero,
    isBeforeZero = trial_time < 0;
    for cov_ind = 1:length(GLMCov),
        if isempty(GLMCov(cov_ind).data), continue; end;
        GLMCov(cov_ind).data(isBeforeZero, :) = [];
    end
    spikes(isBeforeZero, :) = [];
    trial_time(isBeforeZero) = [];
    trial_id(isBeforeZero) = [];
    sample_on(isBeforeZero) = [];
    percent_trials(isBeforeZero) = [];
    isAttempted(isBeforeZero) = [];
end

if ~gamParams.includeFixationBreaks
    for cov_ind = 1:length(GLMCov),
        if isempty(GLMCov(cov_ind).data), continue; end;
        GLMCov(cov_ind).data(~isAttempted, :) = [];
    end
    spikes(~isAttempted, :) = [];
    trial_time(~isAttempted) = [];
    trial_id(~isAttempted) = [];
    sample_on(~isAttempted) = [];
    percent_trials(~isAttempted) = [];
end

[designMatrix, gam] = gamModelMatrix(gamParams.regressionModel_str, GLMCov, 'level_reference', referenceLevel);

clear GLMCov;

% Make sure covariates are of class double
designMatrix = double(designMatrix);

numTrials = length(unique(trial_id));
numPFC = sum(pfc);
numACC = sum(~pfc);

% % Number of trials for each level
% trialIdByDesignMatrix = bsxfun(@times, designMatrix, ones(size(trial_id)));
% trialIdByDesignMatrix = bsxfun(@times, trialIdByDesignMatrix, trial_id);
% trialIdByDesignMatrix(trialIdByDesignMatrix == 0) = NaN;
%
% for k = 1:size(designMatrix, 2),
%     gam.numTrialsByLevel(k) = sum(~isnan(unique(trialIdByDesignMatrix(:, k))));
% end

wire_number = num2cell(wire_number);
unit_number = num2cell(unit_number);
pfc = num2cell(pfc);
brainAreas = {'ACC', 'dlPFC'};
stats = cell([1 numNeurons]);
neurons = cell([1 numNeurons]);
isPrediction = gamParams.isPrediction;
%% Do the fitting
fprintf('\nFitting GAMs ...\n');

% % Parallel Pool Configuration
% poolobj = gcp('nocreate');
% if isempty(poolobj),
%     minWorkers = 2;
%     maxWorkers = 12;
%     parpool([minWorkers, maxWorkers], 'SpmdEnabled', false);
% end

% Remove NaNs beforehand to avoid the memory cost of removing them in fitGaM
wasNaN = any(isnan(spikes), 2) | any(isnan(designMatrix), 2);

%Transfer static assets to each worker only once
if verLessThan('matlab', '8.6'),
    dM = WorkerObjWrapper(designMatrix(~wasNaN, :));
    g = WorkerObjWrapper(gam);
    gP = WorkerObjWrapper(gamParams);
    tI = WorkerObjWrapper(trial_id(~wasNaN, :));
else
    dM = parallel.pool.Constant(designMatrix(~wasNaN, :));
    g = parallel.pool.Constant(gam);
    gP = parallel.pool.Constant(gamParams);
    tI = parallel.pool.Constant(trial_id(~wasNaN, :));
end

spikes = spikes(~wasNaN, :);
% dM.Value = designMatrix(~wasNaN, :);
% g.Value = gam;
% gP.Value = gamParams;
% tI.Value = trial_id(~wasNaN, :);

parfor curNeuron = 1:numNeurons,
    fprintf('\nNeuron %d \n', curNeuron);
    if isPrediction,
        neurons{curNeuron} = predictGAM(dM.Value, spikes(:, curNeuron), g.Value, gP.Value, tI.Value);
    else
        [neurons{curNeuron}, stats{curNeuron}] = estimateGAM(dM.Value, spikes(:, curNeuron), g.Value, gP.Value, tI.Value);
    end
end % End Neuron Loop

for curNeuron = 1:numNeurons,
    neurons{curNeuron}.wire_number = wire_number{curNeuron};
    neurons{curNeuron}.unit_number = unit_number{curNeuron};
    neurons{curNeuron}.session_name = sessionName;
    neurons{curNeuron}.monkey = monkey_name;
    neurons{curNeuron}.brainArea = brainAreas{pfc{curNeuron} + 1};
end

neurons = [neurons{:}];
stats = [stats{:}];

gam.trial_id = trial_id;
gam.trial_time = trial_time;

%% Save to file
fprintf('\nSaving GAMs ...\n');
save(saveFileName, 'neurons', 'stats', ...
    'gam', 'num*', 'gamParams', ...
    'designMatrix', '-v7.3');

fprintf('\nFinished: %s\n', datestr(now));

if ~gamParams.isLocal,
    designMatrix = [];
end

end

%%%%%%%%%%% Function to estimate GAM for a single neuron %%%%%%%%%%%%%%%%%%
function [neuron, stats, fitInfo] = estimateGAM(designMatrix, spikes, gam, gamParams, trial_id)

%% Pick a Lambda if there's more than one, unless there's one specified

[ridgeLambdaGrid, smoothLambdaGrid] = meshgrid(gamParams.ridgeLambda, gamParams.smoothLambda);
ridgeLambdaGrid = ridgeLambdaGrid(:);
smoothLambdaGrid = smoothLambdaGrid(:);

numLambda = length(ridgeLambdaGrid);

% Shut off constant default setting on GLM
const = 'off';

if numLambda > 1 && gamParams.numFolds > 1,
    bestLambda_ind = pickLambda();
else
    bestLambda_ind = 1;
end

%% Fit the best model
lambdaVec = nan([1 size(designMatrix, 2)]);
lambdaVec(gam.constant_ind) = ridgeLambdaGrid(bestLambda_ind);
lambdaVec(~gam.constant_ind) = smoothLambdaGrid(bestLambda_ind);
lambdaVec(1) = 0;

fprintf('Fitting Best Model: Ridge %d, Smooth %d\n', ...
    ridgeLambdaGrid(bestLambda_ind), smoothLambdaGrid(bestLambda_ind));
[neuron.par_est, fitInfo] = fitGAM(designMatrix, spikes, gam.sqrtPen, ...
    'lambda', lambdaVec, 'distr', 'poisson', 'constant', const, ...
    'constraints', gam.constraints);

stats = gamStats(designMatrix, spikes, fitInfo, trial_id, ...
    'Compact', false);

%%%%%%%%%%%%%%%%%% Function to pick a particular smoothing parameter %%%%%%
    function [bestLambda_ind] = pickLambda()
        %         numParam = size(gam.constraints, 1);
        trials = unique(trial_id);
        
        % Cross validate the model on each lambda and choose the best
        % one
        CVO = cvpartition(length(trials), 'Kfold', gamParams.numFolds);
        
        predError = nan(gamParams.numFolds, numLambda);
        %         parEstPath = nan(numParam, numLambda, gamParams.numFolds);
        %         edf = nan(numLambda, gamParams.numFolds);
        
        for curFold = 1:gamParams.numFolds,
            if gamParams.numFolds > 1
                trainingIdx = ismember(trial_id, trials(CVO.training(curFold)));
                testIdx = ismember(trial_id, trials(CVO.test(curFold)));
            else
                trainingIdx = true(size(designMatrix, 1), 1);
                testIdx = true(size(designMatrix, 1), 1);
            end
            
            % Fit the model on each lambda for each fold of the
            % cross validation
            for curLambda = 1:numLambda,
                
                fprintf('\t\t Lambda Selection: Fold #%d, Lambda %d\n', curFold, curLambda);
                pickLambdaVec = nan([1 size(designMatrix, 2)]);
                pickLambdaVec(gam.constant_ind) = ridgeLambdaGrid(curLambda);
                pickLambdaVec(~gam.constant_ind) = smoothLambdaGrid(curLambda);
                pickLambdaVec(1) = 0;
                
                [~, pickLambdaFitInfo] = fitGAM(designMatrix(trainingIdx, :), spikes(trainingIdx), gam.sqrtPen, ...
                    'lambda', pickLambdaVec, 'distr', 'poisson', 'constant', const, ...
                    'constraints', gam.constraints);
                
                %                 edf(curLambda, curFold) = fitInfo.edf;
                
                [pickLambdaStats] = gamStats(designMatrix(testIdx, :), spikes(testIdx), pickLambdaFitInfo, trial_id(testIdx),...
                    'Compact', true);
                
                % Store prediction error
                predError(curFold, curLambda) = pickLambdaStats.(gamParams.predType);
                
            end % End Lambda Loop
            
        end % End Fold Loop
        
        %         parEstPath = parEstPath(2:end, :, :);
        
        % Calculate mean prediction error for best fit model
        meanPredError = nanmean(predError, 1);
        
        % Determine the best lambda for best fit model
        switch (gamParams.predType)
            case {'AUC', 'MI'}
                [~, bestLambda_ind] = max(meanPredError);
            case {'Dev', 'AIC', 'BIC', 'GCV', 'UBRE'}
                [~, bestLambda_ind] = min(meanPredError);
            otherwise
                bestLambda_ind = NaN;
        end
    end

end

%%%%%%%%%%%%%%%% Function to return only predictions of GAM %%%%%%%%%%%%%%%
function [neuron] = predictGAM(designMatrix, spikes, gam, gamParams, trial_id)

neuron.Dev = nan(1, gamParams.numFolds);
neuron.AUC = nan(1, gamParams.numFolds);
neuron.mutualInformation = nan(1, gamParams.numFolds);
trials = unique(trial_id);

if gamParams.numFolds > 1
    CVO = cvpartition(length(trials), 'Kfold', gamParams.numFolds);
end

for curFold = 1:gamParams.numFolds,
    fprintf('\t Prediction: Fold #%d\n', curFold);
    if gamParams.numFolds > 1
        trainingIdx = ismember(trial_id, trials(CVO.training(curFold)));
        testIdx = ismember(trial_id, trials(CVO.test(curFold)));
    else
        trainingIdx = true(size(designMatrix, 1), 1);
        testIdx = true(size(designMatrix, 1), 1);
    end
    
    %% Estimate Model
    [~, ~, fitInfo] = estimateGAM(designMatrix(trainingIdx, :), spikes(trainingIdx), gam, gamParams, trial_id(trainingIdx));
    
    [stats] = gamStats(designMatrix(testIdx, :), spikes(testIdx), fitInfo, trial_id(testIdx),...
        'Compact', true);
    %% Store a prediction on the test set
    neuron.Dev(curFold) = stats.Dev;
    neuron.AUC(curFold) = stats.AUC;
    neuron.mutualInformation(curFold) = stats.mutual_information;
end
neuron.CVO = CVO;

end

