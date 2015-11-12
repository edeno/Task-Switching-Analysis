function [neurons, stats, gam, designMatrix, modelList, gamParams, spikeCov] = ComputeGAMfit(sessionName, gamParams, covInfo)
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
mainDir = getWorkingDir();
timePeriodDir = sprintf('%s/Processed Data/%s/', mainDir, gamParams.timePeriod);
%% Create Model Directory
modelDir = sprintf('%s/Models/', timePeriodDir);

if ~exist(modelDir, 'dir'),
    mkdir(modelDir);
end

if exist(sprintf('%s/Models/modelList.mat', timePeriodDir), 'file'),
    load(sprintf('%s/Models/modelList.mat', timePeriodDir), 'modelList');
    if ~modelList.isKey(gamParams.regressionModel_str)
        modelList(gamParams.regressionModel_str) = sprintf('M%d', modelList.length + 1);
    end
else
    modelList = containers.Map(gamParams.regressionModel_str, 'M1');
end
save(sprintf('%s/Models/modelList.mat', timePeriodDir), 'modelList');

saveDir = sprintf('%s/Models/%s', timePeriodDir, modelList(gamParams.regressionModel_str));

if ~exist(saveDir, 'dir'),
    mkdir(saveDir);
end
%% Setup Save File
if gamParams.isPrediction,
    saveFileName = sprintf('%s/%s_GAMpred.mat', saveDir, sessionName);
else
    saveFileName = sprintf('%s/%s_GAMfit.mat', saveDir, sessionName);
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
dataFileName = sprintf('%s/SpikeCov/%s_SpikeCov.mat', timePeriodDir, sessionName);
load(dataFileName);

% For some reason, matlab freaks out if you don't do this
wireNumber = double(wire_number);
unitNumber = double(unit_number);

monkeyName = regexp(sessionName, '(cc)|(isa)|(ch)|(test)', 'match');
monkeyName = monkeyName{:};
%% Setup Design Matrix
fprintf('\nConstructing model design matrix...\n');
if all(gamParams.ridgeLambda == 0)
    referenceLevel = 'Reference';
else
    referenceLevel = 'Full';
end

covNames = spikeCov.keys;

if ~gamParams.includeIncorrect
    for cov_ind = 1:length(covNames),
        if ~spikeCov.isKey(covNames{cov_ind}), continue; end;
        cov = spikeCov(covNames{cov_ind});
        spikeCov(covNames{cov_ind}) = cov(isCorrect, :);
    end
    spikes(~isCorrect, :) = [];
    trialTime(~isCorrect) = [];
    trialID(~isCorrect) = [];
    percentTrials(~isCorrect) = [];
    isAttempted(~isCorrect) = [];
end

if ~gamParams.includeTimeBeforeZero,
    isBeforeZero = trialTime < 0;
    for cov_ind = 1:length(covNames),
        if ~spikeCov.isKey(covNames{cov_ind}), continue; end;
        cov = spikeCov(covNames{cov_ind});
        spikeCov(covNames{cov_ind}) = cov(~isBeforeZero, :);
    end
    spikes(isBeforeZero, :) = [];
    trialTime(isBeforeZero) = [];
    trialID(isBeforeZero) = [];
    percentTrials(isBeforeZero) = [];
    isAttempted(isBeforeZero) = [];
end

if ~gamParams.includeFixationBreaks
    for cov_ind = 1:length(covNames),
        if ~spikeCov.isKey(covNames{cov_ind}), continue; end;
        cov = spikeCov(covNames{cov_ind});
        spikeCov(covNames{cov_ind}) = cov(isAttempted, :);
    end
    spikes(~isAttempted, :) = [];
    trialTime(~isAttempted) = [];
    trialID(~isAttempted) = [];
    percentTrials(~isAttempted) = [];
end

[designMatrix, gam] = gamModelMatrix(gamParams.regressionModel_str, spikeCov, covInfo, 'level_reference', referenceLevel);

% Make sure covariates are of class double
designMatrix = double(designMatrix);

numTrials = length(unique(trialID));
numPFC = sum(ismember(neuronBrainArea, 'dlPFC'));
numACC = sum(ismember(neuronBrainArea, 'ACC'));

wireNumber = num2cell(wireNumber);
unitNumber = num2cell(unitNumber);
stats = cell([1 numNeurons]);
neurons = cell([1 numNeurons]);
isPrediction = gamParams.isPrediction;
%% Do the fitting
fprintf('\nFitting GAMs ...\n');
% Remove NaNs beforehand to avoid the memory cost of removing them in fitGaM
wasNaN = any(isnan(designMatrix), 2);

%Transfer static assets to each worker only once
if verLessThan('matlab', '8.6'),
    dM = WorkerObjWrapper(designMatrix(~wasNaN, :));
    gP = WorkerObjWrapper(gamParams);
    cI = WorkerObjWrapper(gam.constant_ind);
    sP = WorkerObjWrapper(gam.sqrtPen);
    con = WorkerObjWrapper(gam.constraints);
    tI = WorkerObjWrapper(trialID(~wasNaN, :));
else
    dM = parallel.pool.Constant(designMatrix(~wasNaN, :));
    cI = parallel.pool.Constant(gam.constant_ind);
    sP = parallel.pool.Constant(gam.sqrtPen);
    con = parallel.pool.Constant(gam.constraints);
    gP = parallel.pool.Constant(gamParams);
    tI = parallel.pool.Constant(trialID(~wasNaN, :));
end

spikes = spikes(~wasNaN, :);
% dM.Value = designMatrix(~wasNaN, :);
% cI.Value = gam.constant_ind;
% sP.Value = gam.sqrtPen;
% con.Value = gam.constraints;
% gP.Value = gamParams;
% tI.Value = trialID(~wasNaN, :);

parfor curNeuron = 1:numNeurons,
    if isPrediction,
        neurons{curNeuron} = predictGAM(dM.Value, spikes(:, curNeuron), cI.Value, sP.Value, con.Value, gP.Value, tI.Value, curNeuron);
    else
        [neurons{curNeuron}, stats{curNeuron}] = estimateGAM(dM.Value, spikes(:, curNeuron), cI.Value, sP.Value, con.Value, gP.Value, tI.Value, curNeuron);
    end
end % End Neuron Loop

for curNeuron = 1:numNeurons,
    neurons{curNeuron}.wireNumber = wireNumber{curNeuron};
    neurons{curNeuron}.unitNumber = unitNumber{curNeuron};
    neurons{curNeuron}.sessionName = sessionName;
    neurons{curNeuron}.monkeyName = monkeyName;
    neurons{curNeuron}.brainArea = neuronBrainArea{curNeuron};
end

neurons = [neurons{:}];
stats = [stats{:}];

gam.trialID = trialID;
gam.trialTime = trialTime;
%% Save to file
fprintf('\nSaving GAMs ...\n');
save(saveFileName, 'neurons', 'stats', ...
    'gam', 'num*', 'gamParams', ...
    'designMatrix', 'spikeCov', '-v7.3');

fprintf('\nFinished: %s\n', datestr(now));

if ~gamParams.isLocal,
    designMatrix = [];
    spikeCov = [];
end
end

%%%%%%%%%%% Function to estimate GAM for a single neuron %%%%%%%%%%%%%%%%%%
function [neuron, stats, fitInfo] = estimateGAM(designMatrix, spikes, constant_ind, sqrtPen, constraints, gamParams, trialID, neuron_ind)

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
lambdaVec(constant_ind) = ridgeLambdaGrid(bestLambda_ind);
lambdaVec(~constant_ind) = smoothLambdaGrid(bestLambda_ind);
lambdaVec(1) = 0;

fprintf('Fitting Best Model for Neuron #%d: Ridge %d, Smooth %d\n', ...
    neuron_ind, ridgeLambdaGrid(bestLambda_ind), smoothLambdaGrid(bestLambda_ind));
[neuron.parEst, fitInfo] = fitGAM(designMatrix, spikes, sqrtPen, ...
    'lambda', lambdaVec, 'distr', 'poisson', 'constant', const, ...
    'constraints', constraints);

stats = gamStats(designMatrix, spikes, fitInfo, trialID, ...
    'Compact', false);

%%%%%%%%%%%%%%%%%% Function to pick a particular smoothing parameter %%%%%%
    function [bestLambda_ind] = pickLambda()
        %         numParam = size(constraints, 1);
        trials = unique(trialID);
        
        % Cross validate the model on each lambda and choose the best
        % one
        CVO = cvpartition(length(trials), 'Kfold', gamParams.numFolds);
        
        predError = nan(gamParams.numFolds, numLambda);
        %         parEstPath = nan(numParam, numLambda, gamParams.numFolds);
        %         edf = nan(numLambda, gamParams.numFolds);
        
        for curFold = 1:gamParams.numFolds,
            if gamParams.numFolds > 1
                trainingIdx = ismember(trialID, trials(CVO.training(curFold)));
                testIdx = ismember(trialID, trials(CVO.test(curFold)));
            else
                trainingIdx = true(size(designMatrix, 1), 1);
                testIdx = true(size(designMatrix, 1), 1);
            end
            
            % Fit the model on each lambda for each fold of the
            % cross validation
            for curLambda = 1:numLambda,
                
                fprintf('\t\t Lambda Selection: Neuron #%d, Fold #%d, Lambda %d\n', neuron_ind, curFold, curLambda);
                pickLambdaVec = nan([1 size(designMatrix, 2)]);
                pickLambdaVec(constant_ind) = ridgeLambdaGrid(curLambda);
                pickLambdaVec(~constant_ind) = smoothLambdaGrid(curLambda);
                pickLambdaVec(1) = 0;
                
                [~, pickLambdaFitInfo] = fitGAM(designMatrix(trainingIdx, :), spikes(trainingIdx), sqrtPen, ...
                    'lambda', pickLambdaVec, 'distr', 'poisson', 'constant', const, ...
                    'constraints', constraints);
                
                %                 edf(curLambda, curFold) = fitInfo.edf;
                
                [pickLambdaStats] = gamStats(designMatrix(testIdx, :), spikes(testIdx), pickLambdaFitInfo, trialID(testIdx),...
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
function [neuron] = predictGAM(designMatrix, spikes, constant_ind, sqrtPen, constraints, gamParams, trialID, neuron_ind)

neuron.Dev = nan(1, gamParams.numFolds);
neuron.AUC = nan(1, gamParams.numFolds);
neuron.mutualInformation = nan(1, gamParams.numFolds);
trials = unique(trialID);

if gamParams.numFolds > 1
    CVO = cvpartition(length(trials), 'Kfold', gamParams.numFolds);
end

for curFold = 1:gamParams.numFolds,
    fprintf('\t Prediction: Fold #%d\n', curFold);
    if gamParams.numFolds > 1
        trainingIdx = ismember(trialID, trials(CVO.training(curFold)));
        testIdx = ismember(trialID, trials(CVO.test(curFold)));
    else
        trainingIdx = true(size(designMatrix, 1), 1);
        testIdx = true(size(designMatrix, 1), 1);
    end
    
    %% Estimate Model
    [~, ~, fitInfo] = estimateGAM(designMatrix(trainingIdx, :), spikes(trainingIdx), constant_ind, sqrtPen, constraints, gamParams, trialID(trainingIdx), neuron_ind);
    
    [stats] = gamStats(designMatrix(testIdx, :), spikes(testIdx), fitInfo, trialID(testIdx),...
        'Compact', true);
    %% Store a prediction on the test set
    neuron.Dev(curFold) = stats.Dev;
    neuron.AUC(curFold) = stats.AUC;
    neuron.mutualInformation(curFold) = stats.mutual_information;
end
neuron.CVO = CVO;

end

