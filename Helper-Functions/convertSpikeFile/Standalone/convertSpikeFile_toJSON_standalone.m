function [] = convertSpikeFile_toJSON_standalone(session_ind, varargin)
%#function getWorkingDir
%#function convertSpikeFile_toJSON

fprintf('\nMatlab\n')
fprintf('---------\n')
fprintf('Session_ind: %s\n', session_ind);

% Numbers are passed as strings. Need to convert to correct type
session_ind = str2double(session_ind);

%% Validate Parameters
workingDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', workingDir), 'sessionNames');
saveDir = sprintf('%s/Figures/Entire Trial/Visualization Data/', workingDir);

if ~exist(saveDir, 'dir'),
    mkdir(saveDir);
end

myCluster = parcluster('local');
if getenv('ENVIRONMENT')    % true if this is a batch job
    myCluster.JobStorageLocation = getenv('TMPDIR');  % points to TMPDIR
end

numCores = 12;
parpool(myCluster, numCores);
fprintf('Session Name: %s\n', sessionNames{session_ind});
convertSpikeFile_toJSON(sessionNames{session_ind}, saveDir);
exit;
end
