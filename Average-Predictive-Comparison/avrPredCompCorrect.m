% This function computes the average predictive comparison between rules at
% a particular level of another covariate (the "by" variable).
% For example, we could compute the average difference between rules when
% an error has been committed in the previous trial or when the monkey
% saccades to the left.
function [avpred] = avrPredCompCorrect(model, factorOfInterest, varargin)
inParser = inputParser;
inParser.addRequired('model', @ischar);
inParser.addRequired('factorOfInterest', @ischar);
inParser.addParameter('Monkey', 'All');
inParser.addParameter('Session', 'All');
inParser.addParameter('correctTrialsOnly', false);
inParser.addParameter('numSim', 1000);
inParser.addParameter('numSamples', []);
inParser.addParameter('numCores', 0);
inParser.addParameter('isWeighted', false);
inParser.addParameter('overwrite', true);
inParser.parse(model, factorOfInterest, varargin{:});
apcParams = inParser.Results;
%% Log parameters
fprintf('\n------------------------\n');
fprintf('\nDate: %s\n \n', datestr(now));
fprintf('\nAPC Parameters\n');
fprintf('\t model: %s\n', apcParams.model);
fprintf('\t factorOfInterest: %s\n', apcParams.factorOfInterest);
fprintf('\t numSim: %d\n', apcParams.numSim);
fprintf('\t isWeighted: %d\n', apcParams.isWeighted);
fprintf('\t overwrite: %d\n', apcParams.overwrite);

%% Load covariate fit and model fit information
main_dir = getWorkingDir();
saveFolder = sprintf('%s/Behavior/', main_dir);
saveFileName = sprintf('%s/%s_Correct_APC.mat', saveFolder, apcParams.factorOfInterest);
if exist(saveFileName, 'file') && ~apcParams.overwrite,
    fprintf('/nFile already exists...exiting/n');
    return;
end
load(sprintf('%s/paramSet.mat', main_dir), 'covInfo');
load(sprintf('%s/Behavior/behavior.mat', main_dir));
behavior = mergeMap(behavior);

monkey = bsxfun(@or, strcmpi({apcParams.Monkey}, behavior('Monkey')), strcmpi(apcParams.Monkey, 'All'));
sessions = bsxfun(@or, strcmpi({apcParams.Session}, behavior('Session Name')), strcmpi(apcParams.Session, 'All'));
filter_ind = monkey & sessions;
if apcParams.correctTrialsOnly,
    filter_ind = filter_ind & behavior('Correct');
end

[designMatrix, gam] = gamModelMatrix(apcParams.model, behavior, covInfo, 'level_reference', 'Reference');
designMatrix = designMatrix(filter_ind, :);

% Reaction Time
correct = double(behavior('Correct'));
correct = correct(filter_ind);

[beta, ~, stat] = glmfit(designMatrix, correct, 'binomial','link','logit', 'constant', 'off');
lowerBnd = log(eps('double')); upperBnd = -lowerBnd;
ilink = @(eta) 1 ./ (1 + exp(-constrain(eta,lowerBnd,upperBnd)));
% Get the names of the covariates for the current model
model = modelFormulaParse(apcParams.model);
covNames = gam.covNames;

numData = size(designMatrix, 1);

% Simulate from posterior
parEst = mvnrnd(beta, stat.covb, apcParams.numSim)';

% Find the covariate index for the current variable, the variable to be held
% constant and the other inputs
otherNames = covNames(ismember(covNames, model.terms) & ~ismember(covNames, apcParams.factorOfInterest));

factorData = behavior(apcParams.factorOfInterest);
if ~isempty(otherNames),
    otherData = cellfun(@(x) behavior(x), otherNames, 'UniformOutput', false);
    
    isCategorical = cell2mat(cellfun(@(x) covInfo(x).isCategorical, otherNames, 'UniformOutput', false));
    isCategorical(ismember(otherNames, {'Rule Repetition', 'Previous Error History Indicator'})) = false;
    
    otherData(isCategorical) = cellfun(@(x) dummyvar(x), otherData(isCategorical), 'UniformOutput', false);
    
    isCategorical = cellfun(@(categorical, data) repmat(categorical, [1 size(data, 2)]), num2cell(isCategorical), otherData, 'UniformOutput', false);
else
    isCategorical = {};
    otherData = {};
end

if covInfo(apcParams.factorOfInterest).isCategorical,
    levels = covInfo(apcParams.factorOfInterest).levels;
else
    % Assume normalized continuous variable
    levels = [strcat('-', covInfo(apcParams.factorOfInterest).levels), covInfo(apcParams.factorOfInterest).levels];
    levelsID = [-1 1];
end

numHistoryFactors = size(factorData, 2);

% If the factor is a history variable, then we need to loop over each
% history variable. If the factor is an ordered categorical variable with
% more than two levels, we need to calculate the different between all the
% other levels and the last level. Currently no support for unordered
% categorical variables that aren't binary.
counter_idx = 1;
origCov = behavior(apcParams.factorOfInterest);
baselineLevel_ind = ismember(covInfo(apcParams.factorOfInterest).levels, covInfo(apcParams.factorOfInterest).baselineLevel);

apc = nan(1, apcParams.numSim);
abs_apc = nan(1, apcParams.numSim);
norm_apc = nan(1, apcParams.numSim);

% Cut down on the number of data points by sampling
if ~isempty(apcParams.numSamples),
    if numData <= apcParams.numSamples,
        sample_ind = 1:numData;
    else
        sample_ind = sort(randperm(numData, apcParams.numSamples));
        numData = apcParams.numSamples;
    end
else
    sample_ind = 1:numData;
end

%% Create matlab pool
fprintf('\nCreate matlab pool...\n');
myCluster = parcluster('local');
tempDir = tempname;
mkdir(tempDir);
myCluster.JobStorageLocation = tempDir;  % points to TMPDIR

poolobj = gcp('nocreate'); % If no pool, do not create new one.
if isempty(poolobj) && apcParams.numCores > 0
    parpool(myCluster, min([apcParams.numCores, myCluster.NumWorkers]));
end

for history_ind = 1:numHistoryFactors,
    %% Figure out the matrix of other inputs
    fprintf('\nLoop over history variable #%d...\n', history_ind);
    if ismember(apcParams.factorOfInterest, {'Previous Error History', 'Congruency History'}),
        history = factorData(:, ~ismember(1:numHistoryFactors, history_ind));
        history = dummyvar(history);
        if history_ind == 1,
            curLevels = reshape(levels, [], numHistoryFactors)';
            baselineLevel_ind = reshape(baselineLevel_ind, [], numHistoryFactors)';
        end
    else
        history = [];
        curLevels = levels;
    end
    
    other_inputs = [otherData{:} history];
    if ~isempty(other_inputs),
        other_inputs = other_inputs(sample_ind, :);
    end
    %% Compute covariance matrix used for Mahalanobis distances:
    % Find weights
    fprintf('\nFind weights...\n');
    other_isCategorical = [isCategorical{:} true(1, size(history ,2))];
    if apcParams.isWeighted,
        summedWeights = apc_weights(other_inputs, other_isCategorical);
    else
        summedWeights = [];
    end
    if isempty(summedWeights),
        summedWeights = ones(numData, 1);
    end
    den = summedWeights;
    %% Compute the difference between the baseline level and all other levels
    if covInfo(apcParams.factorOfInterest).isCategorical,
        levelData = unique(factorData(:, ismember(history_ind, 1:numHistoryFactors)));
        levelData(isnan(levelData)) = [];
    else
        levelData = [-1 1];
    end
    
    % Compute the firing rate holding thne last level constant (only need to do this once)
    cov = origCov;
    cov(:, history_ind) = levelData(baselineLevel_ind(history_ind, :));
    behavior(apcParams.factorOfInterest) = cov;
    baselineDesignMatrix = gamModelMatrix(apcParams.model, behavior, covInfo, 'level_reference', gam.level_reference);
    baselineDesignMatrix = baselineDesignMatrix(sample_ind, :) * gam.constraints';
    baselineLevelName = curLevels{history_ind, baselineLevel_ind(history_ind, :)};
    
    % Number of levels to iterate over.
    levelID = find(~ismember(curLevels(history_ind, :), baselineLevelName));
    numLevels = length(levelID);
    
    for level_ind = 1:numLevels,
        cov(:, history_ind) = levelData(levelID(level_ind));
        behavior(apcParams.factorOfInterest) = cov;
        curLevelDesignMatrix = gamModelMatrix(apcParams.model, behavior, covInfo, 'level_reference', gam.level_reference);
        curLevelDesignMatrix = curLevelDesignMatrix(sample_ind, :) * gam.constraints';
        curLevelName = curLevels{history_ind, levelID(level_ind)};
        %Transfer static assets to each worker only once
        fprintf('\nTransferring static assets to each worker...\n');
        if apcParams.numCores > 0
            if verLessThan('matlab', '8.6'),
                cLDM = WorkerObjWrapper(curLevelDesignMatrix);
                bDM = WorkerObjWrapper(baselineDesignMatrix);
                d = WorkerObjWrapper(den);
                sW = WorkerObjWrapper(summedWeights);
            else
                cLDM = parallel.pool.Constant(curLevelDesignMatrix);
                bDM = parallel.pool.Constant(baselineDesignMatrix);
                d = parallel.pool.Constant(den);
                sW = parallel.pool.Constant(summedWeights);
            end
        else
            cLDM.Value = curLevelDesignMatrix;
            bDM.Value = baselineDesignMatrix;
            d.Value = den;
            sW.Value = summedWeights;
        end
        fprintf('\nComputing Level: %s...\n', curLevelName);
        for sim_ind = 1:apcParams.numSim,
            if (mod(sim_ind, 100) == 0)
                fprintf('\t\tSim #%d...\n', sim_ind);
            end
            curLevelEst = ilink(cLDM.Value * squeeze(parEst(:, sim_ind)));
            baselineLevelEst = ilink(bDM.Value * squeeze(parEst(:, sim_ind)));
            diffEst = bsxfun(@times, sW.Value, curLevelEst - baselineLevelEst);
            sumEst = curLevelEst + baselineLevelEst;
            
            apc(sim_ind) = nanmean(diffEst ./ d.Value);
            abs_apc(sim_ind) = nanmean(abs(diffEst) ./ d.Value);
            norm_apc(sim_ind) = nanmean(diffEst ./ sumEst ./ d.Value);
        end
        avpred.apc(counter_idx, :) = apc;
        avpred.abs_apc(counter_idx, :) = abs_apc;
        avpred.norm_apc(counter_idx, :) = norm_apc;
        comparisonNames{counter_idx} = sprintf('%s - %s', curLevelName, baselineLevelName);
        counter_idx = counter_idx + 1;
    end
    
end

[avpred.numSamples] = deal(apcParams.numSamples);
[avpred.numSim] = deal(apcParams.numSim);
[avpred.model] = deal(apcParams.model);
[avpred.comparisonNames] = deal(comparisonNames);

fprintf('\nSaving...\n');
save(saveFileName, 'avpred', '-v7.3');
fprintf('\nFinished: %s\n', datestr(now));

end

function x = constrain(x,lower,upper)
% Constrain between upper and lower limits, and do not ignore NaN
x(x<lower) = lower;
x(x>upper) = upper;
end
