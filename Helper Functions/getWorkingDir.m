function [directory] = getWorkingDir()
% specify custom working directory
computerNames = {'cns-ws18', ...
    'millerdata', ...
    'Erics-MacBook-Air', ...
    'scc'};
directories = {'C:\Users\edeno\Documents\GitHub\Task-Switching-Analysis\', ...
    '/data/home/edeno/Task-Switching-Analysis/', ...
    '/Users/edeno/Documents/GitHub/Task-Switching-Analysis/', ...
    '/projectnb/pfc-rule/Task-Switching-Analysis/'};

workingDir = containers.Map(computerNames, directories);
if ispc,
    [~, hostname] = system('hostname');
else
    [~, hostname] = system('hostname -f');
end
hostname = strtrim(hostname);

% Make all cluster nodes save to the same space
if strfind(hostname, 'scc'),
    hostname = 'scc';
end
if strfind(hostname, 'millerdata'),
    hostname = 'millerdata';
end

if workingDir.isKey(hostname),
    directory = workingDir(hostname);
else
    directory = '/projectnb/pfc-rule/Task-Switching-Analysis/'; % Hacky default to assume we're on the cluster
end