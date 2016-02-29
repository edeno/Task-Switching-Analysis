clear variables;

models = {'s(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50)', ...
          's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule, Trial Time, knotDiff=50)'};
timePeriods = {'Rule Response'};
apcType = 'norm_apc';

for time_ind = 1:length(timePeriods),
    timePeriod = timePeriods{time_ind};
    fprintf('\nTime Period: %s\n', timePeriod');
    for model_ind = 1:length(models),
        modelName = models{model_ind};
        fprintf('\nModel: %s\n', modelName');
        main_dir = getWorkingDir();
        modelsDir = sprintf('%s/Processed Data/%s/Models', main_dir, timePeriod);
        load(sprintf('%s/modelList.mat', modelsDir));
        
        apcFolder = sprintf('%s/%s/APC/', modelsDir, modelList(modelName));
        covFolderNames = dir(apcFolder);
        covFolderNames = {covFolderNames.name};
        covFolderNames = covFolderNames(~ismember(covFolderNames, {'.', '..'}));
        
        for folder_ind = 1:length(covFolderNames),
            fprintf('\tFactor of Interest: %s\n', covFolderNames{folder_ind});
            
            curFolder = sprintf('%s/%s', apcFolder, covFolderNames{folder_ind});
            fileNames = dir(sprintf('%s/*.mat', curFolder));
            fileNames = {fileNames.name};
            count = 1;
            for file_ind = 1:length(fileNames),
                curFile = load(sprintf('%s/%s', curFolder, fileNames{file_ind}));
                fprintf('\t\tSession: %s...\n', fileNames{file_ind});
                for neuron_ind = 1:length(curFile.avpred),
                    if folder_ind > 1,
                        assert( ...
                            strcmp(apcJSON(count).name, ...
                            sprintf('%s_%d_%d', ...
                            curFile.avpred(neuron_ind).sessionName, ...
                            curFile.avpred(neuron_ind).wireNumber, ...
                            curFile.avpred(neuron_ind).unitNumber)) ...
                            );
                    else
                        apcJSON(count).name = sprintf('%s_%d_%d', ...
                            curFile.avpred(neuron_ind).sessionName, ...
                            curFile.avpred(neuron_ind).wireNumber, ...
                            curFile.avpred(neuron_ind).unitNumber);
                        apcJSON(count).subject = curFile.avpred(neuron_ind).monkeyNames;
                        apcJSON(count).session = curFile.avpred(neuron_ind).sessionName;
                        apcJSON(count).wireNumber = curFile.avpred(neuron_ind).wireNumber;
                        apcJSON(count).unitNumber = curFile.avpred(neuron_ind).unitNumber;
                        apcJSON(count).brainArea = curFile.avpred(neuron_ind).brainArea;
                        apcJSON(count).averageFiringRate = nanmean(curFile.avpred(neuron_ind).baselineFiringRate);
                        apcJSON(count).time = curFile.avpred(neuron_ind).trialTime;
                    end
                    
                    
                    sanitizedComparisonName = regexprep(curFile.avpred(neuron_ind).comparisonNames, '\s+', '_');
                    sanitizedComparisonName = regexprep(sanitizedComparisonName, '-', 'minus');
                    sanitizedComparisonName = matlab.lang.makeValidName(sanitizedComparisonName{1});
                    apcJSON(count).factors.(sanitizedComparisonName) = mean(curFile.avpred(neuron_ind).(apcType), 3)';
                    
                    count = count + 1;
                end
            end
            
            modelInfo.levelToFactorMap.(sanitizedComparisonName) = covFolderNames{folder_ind};
        end
        
        
        modelInfo.modelNames.modelList(modelName) = modelName;
        modelInfo.eventNames = timePeriod;
        modelInfo.type = apcType;
        
        %% Save model
        save_dir = sprintf('%s/Figures/Entire Trial/', main_dir);
        opt.FileName = sprintf('%s/model_%s_%s_%s.json', save_dir, timePeriod, modelList(modelName), apcType);
        opt.NaN = 'null';
        opt.Compact = 0;
        
        savejson('', apcJSON, opt);
    end
end

%% Save Model info
save_dir = sprintf('%s/Figures/Entire Trial/', main_dir);
opt.FileName = sprintf('%s/modelInfo.json', save_dir);
opt.NaN = 'null';
opt.Compact = 0;

savejson('', modelInfo, opt);