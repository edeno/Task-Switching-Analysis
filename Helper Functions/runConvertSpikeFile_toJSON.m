% Load Common Parameters
workingDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', workingDir), 'sessionNames');

%% Set Parameters
saveDir = sprintf('%s/Figures/Entire Trial/Visualization Data/', workingDir);

if ~exist(saveDir, 'dir'),
    mkdir(saveDir);
end

%% Process Data

% Loop through files in the data directory
for session_ind = 1:length(sessionNames),
    fprintf('\nSession name: %s\n', sessionNames{session_ind});
    convertSpikeFile_toJSON(sessionNames{session_ind}, saveDir)
end