function [timeEst, time, modelTerms] = getSplineCoef(modelName, timePeriod, varargin)
inParser = inputParser;
inParser.addRequired('modelName', @ischar);
inParser.addRequired('timePeriod', @ischar);
inParser.addParameter('brainArea', '*', @ischar);
inParser.addParameter('subject', '*', @ischar);
inParser.addParameter('sessionName', '*', @ischar);
inParser.addParameter('isSim', false, @islogical)
inParser.addParameter('numSim', 1000, @(x) isnumeric(x) & all(x > 0));

inParser.parse(modelName, timePeriod, varargin{:});
params = inParser.Results;

modelTerms = modelFormulaParse(modelName);

workingDir = getWorkingDir();
modelsDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
mL = load(sprintf('%s/modelList.mat', modelsDir));
modelList = mL.modelList;
pS = load(sprintf('%s/paramSet.mat', workingDir), 'sessionNames', 'covInfo');
sessionNames = pS.sessionNames;
covInfo = pS.covInfo;

if strcmp(params.sessionName, '*')
    neuronFiles = sprintf('%s/%s/%s_neuron_%s*_GAMfit.mat', modelsDir, modelList(modelName), params.brainArea, params.subject);
    if ~strcmp(params.subject, '*')
        sessionNames = sessionNames(cellfun(@(x) ~isempty(x), strfind(sessionNames, params.subject)));
    end
else
    neuronFiles = sprintf('%s/%s/%s_neuron_%s_*_GAMfit.mat', modelsDir, modelList(modelName), params.brainArea, params.sessionName);
    sessionNames = sessionNames(cellfun(@(x) ~isempty(x), strfind(sessionNames, params.sessionName)));
end

neuronFiles = dir(neuronFiles);
neuronFiles = {neuronFiles.name};

nameSplit = cellfun(@(x) strsplit(x, '_'), neuronFiles, 'UniformOutput', false);
neuronNames = cellfun(@(x) strjoin(x(:, 3:5), '-'), nameSplit, 'UniformOutput', false);
neuronBrainAreas = cellfun(@(x) x{:, 1}, nameSplit, 'UniformOutput', false);

gam = cell(length(sessionNames), 1);
for session_ind = 1:length(sessionNames),
    fprintf('\nLoading... %s\n', sessionNames{session_ind});
    file = load(sprintf('%s/%s/%s_GAMfit.mat', modelsDir, modelList(modelName), sessionNames{session_ind}), 'gam');
    file.gam = rmfield(file.gam, {'penalty', 'sqrtPen', 'trialID','trialTime'});
    if ~isempty([file.gam.bsplines{:}])
        file.gam.bsplines = cellfun(@(x) rmfield(x, {'time', 'basis', 'sqrtPen', 'penalty', 'con_basis', 'con_sqrtPen', 'knotsDiff', 'rank'}), file.gam.bsplines);
    end
    gam{session_ind} =  file.gam;
end

gam = [gam{:}];
maxTimeLength = arrayfun(@(g) length(g.bsplines(1).x), gam, 'UniformOutput', false);
[numTime, max_ind] = max([maxTimeLength{:}]);

timeEst = cell(length(neuronFiles), 1);

for file_ind = 1:length(neuronFiles),
    fprintf('\nLoading... %s\n', neuronFiles{file_ind});
    file = load(sprintf('%s/%s/%s', modelsDir, modelList(modelName), neuronFiles{file_ind}));
    sessionID = ismember(sessionNames, file.neuron.sessionName);
    timeEst{file_ind} = getTimeEst();
end

time = gam(max_ind).bsplines.x;
timeEst = [timeEst{:}];
%%
    function [timeEst] = getTimeEst()
        timeEst.neuronName = neuronNames{file_ind};
        timeEst.brainArea = file.neuron.brainArea;
        timeEst.subject = file.neuron.monkeyName;
        if params.isSim,
            file.neuron.parEst = mvnrnd(file.neuron.parEst, file.stat.covb, params.numSim)';
        end
        for cov_ind = 1:length(modelTerms.terms),
            curLevels = covInfo(modelTerms.terms{cov_ind}).levels;
            curLevels = curLevels(~ismember(curLevels, covInfo(modelTerms.terms{cov_ind}).baselineLevel));
            validCovName = strrep(modelTerms.terms{cov_ind}, ' ', '_');
            if params.isSim,
                timeEst.(validCovName) = nan(length(curLevels), numTime, params.numSim);
            else
                timeEst.(validCovName) = nan(length(curLevels), numTime);
            end
            for level_ind = 1:length(curLevels),
                time_ind = 1:length(gam(sessionID).bsplines(cov_ind).x);
                timeEst.(validCovName)(level_ind, time_ind, :) = ...
                    getLevelTimeEst( ...
                    gam(sessionID).bsplines(cov_ind).unique_basis, ...
                    gam(sessionID).bsplines(cov_ind).constraint, ...
                    curLevels{level_ind});
            end
        end
    end

%%
    function [timeEst] = getLevelTimeEst(unique_basis, constraint, levelOfInterest)
        findTimeLevel = @(cov) cellfun(@(x) ~isempty(x), regexp(gam(sessionID).levelNames, sprintf('^%s.Trial Time.*', cov)));
        findConstantLevel = @(cov) cellfun(@(x) ~isempty(x), regexp(gam(sessionID).levelNames, sprintf('%s$', cov)));
        
        timeEst = unique_basis * constraint * file.neuron.parEst(findTimeLevel(levelOfInterest), :);
        timeEst = bsxfun(@plus, file.neuron.parEst(findConstantLevel(levelOfInterest), :), timeEst);
    end
end
