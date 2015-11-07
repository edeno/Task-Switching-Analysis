function [directory] = getWorkingDir()
% specify custom working directory
computerNames = {'cns-ws18', ...
    'millerdata', ...
    'Erics-MacBook-Air', ...
    'scc'};
directories = {'C:\Users\edeno\Task-Switching-Analysis\', ...
    '/data/home/edeno/Task-Switching-Analysis/', ...
    '/Users/edeno/Documents/GitHub/Task-Switching-Analysis/', ...
    '/projectnb/pfc-rule/Task-Switching-Analysis/'};

workingDir = containers.Map(computerNames, directories);
[~, hostname] = system('hostname');
hostname = strtrim(hostname);

 % Make all cluster nodes save to the same space
if strcmp('scc', regexp(hostname,'scc*', 'match')),
    hostname = 'scc';
end

if workingDir.isKey(hostname),
    directory = workingDir(hostname);
else
    directory = '/projectnb/pfc-rule/Task-Switching-Analysis/'; % Hacky default to assume we're on the cluster
end
