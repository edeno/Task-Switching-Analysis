function [timeEst, time, modelTerms, gam] = getEstOverTime(neuronName, timePeriod, model)
modelTerms = modelFormulaParse(model);

workingDir = getWorkingDir();
modelsDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
mL = load(sprintf('%s/modelList.mat', modelsDir));
modelList = mL.modelList;
cI = load(sprintf('%s/paramSet.mat', workingDir), 'covInfo');
covInfo = cI.covInfo;

splitName = strsplit(neuronName, '-');
sessionName = splitName{1};
curWire = str2double(splitName{2});
curUnit = str2double(splitName{3});

g = load(sprintf('%s/%s/%s_GAMfit.mat', modelsDir, modelList(model), sessionName), 'gam');
gam = g.gam;
findTimeLevel = @(cov) cellfun(@(x) ~isempty(x), regexp(gam.levelNames, sprintf('^%s.Trial Time.*', cov)));
findConstantLevel = @(cov) cellfun(@(x) ~isempty(x), regexp(gam.levelNames, sprintf('%s$', cov)));
d = dir(sprintf('%s/%s/*_neuron_%s_%d_%d_GAMfit.mat', modelsDir, modelList(model), sessionName, curWire, curUnit));
file = load(sprintf('%s/%s/%s',  modelsDir, modelList(model), d.name));

time = unique(gam.trialTime);
timeEst = cell(size(modelTerms.terms));
getTimeEst();

    function getTimeEst()
        for cov_ind = 1:length(modelTerms.terms),
            curLevels = covInfo(modelTerms.terms{cov_ind}).levels;
            curLevels = curLevels(~ismember(curLevels, covInfo(modelTerms.terms{cov_ind}).baselineLevel));
            
            for level_ind = 1:length(curLevels),
                time_ind = 1:length(time);
                if isempty(gam.bsplines{cov_ind})
                    unique_basis = 1;
                    constraint = 1;
                    timeEst{cov_ind}(level_ind, time_ind, :) = ...
                        getLevelTimeEst( ...
                        unique_basis, ...
                        constraint, ...
                        curLevels{level_ind});
                else
                    timeEst{cov_ind}(level_ind, time_ind, :) = ...
                        getLevelTimeEst( ...
                        gam.bsplines{cov_ind}.unique_basis, ...
                        gam.bsplines{cov_ind}.constraint, ...
                        curLevels{level_ind});
                end
            end
        end
    end

%%
    function [timeEst] = getLevelTimeEst(unique_basis, constraint, levelOfInterest)
        
        timeEst = unique_basis * constraint * file.neuron.parEst(findTimeLevel(levelOfInterest), :);
        if ~isempty(timeEst)
            timeEst = timeEst + file.neuron.parEst(findConstantLevel(levelOfInterest), :);
        else
            timeEst = file.neuron.parEst(findConstantLevel(levelOfInterest), :) .* ones(size(time));
        end
    end
end