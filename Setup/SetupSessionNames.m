%% Setup Session Names
main_dir = getWorkingDir();
rawData_dir = sprintf('%s/Raw Data/', main_dir);

files = dir(sprintf('%s/*.sdt', rawData_dir));
sessionNames = cellfun(@(x) regexprep(x, '.sdt', ''), {files.name}, 'UniformOutput', false);
numSessions = length(sessionNames);
%% Append Information to paramSet
save(sprintf('%s/paramSet.mat', main_dir), 'sessionNames', 'numSessions', '-append');