function [directory] = getWorkingDir()
% specify custom working directory
computerNames = {'cns-ws18', ...
    'millerdata', ...
    'Erics-MacBook-Air'};
directories = {'C:\Users\edeno\Task Switching Analysis\', ...
    '/data/home/edeno/Task Switching Analysis/', ...
    '/Users/edeno/Documents/GitHub/Task-Switching-Analysis/'};

workingDir = containers.Map(computerNames, directories);
[~, hostname] = system('hostname');
hostname = strtrim(hostname);

if workingDir.isKey(hostname),
    directory = workingDir(hostname);
else
    directory = sprintf('%s/Task Switching Analysis/', pwd);
end
