%% Collects GAMfit session files into one file
clear variables; clc;
main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), 'validFolders');
isLocal = false;

if isLocal,
    for time_ind = 1:length(validFolders),
        fprintf('\nTime Period: %s\n', validFolders{time_ind});
        collectGAMfit(validFolders{time_ind});
    end
else
    % Use Cluster
    job = TorqueJob('collectGAMfit', {validFolders}, ...
        'walltime=4:00:00,mem=16GB');
end