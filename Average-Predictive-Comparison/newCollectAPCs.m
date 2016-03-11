workingDir = getWorkingDir();
timePeriod = 'Rule Response';
modelDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
load(sprintf('%s/modelList.mat', modelDir));
model = 'Rule * Previous Error + Response Direction + Rule * Rule Repetition + Congruency';
apcDir = sprintf('%s/%s/APC/', modelDir, modelList(model));

folderNames = dir(apcDir);
folderNames = {folderNames.name};
folderNames = folderNames(~ismember(folderNames, {'.', '..'}));

for folder_ind = 1:length(folderNames),
    fprintf('\nFolder: %s\n', folderNames{folder_ind});
    APC_files = dir(sprintf('%s/%s/*_APC.mat', apcDir, folderNames{folder_ind}));
    APC_files = {APC_files.name};
    avpred = [];

    for file_ind = 1:length(APC_files),
        fprintf('\t...%s\n', APC_files{file_ind})
        curAPC = load(APC_files{file_ind});
        avpred = [avpred, curAPC.avpred];
    end

    saveDir = sprintf('%s/%s/apcCollected/', apcDir, folderNames{folder_ind});
    if ~exist(saveDir, 'dir'),
        mkdir(saveDir);
    end
    summarizeAPC(avpred, saveDir);
end
