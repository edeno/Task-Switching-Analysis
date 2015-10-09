%% Setup Session Names
main_dir = getWorkingDir();
rawData_dir = sprintf('%s/Raw Data/', main_dir);

files = dir(sprintf('%s/*.sdt', rawData_dir));
session_names = cellfun(@(x) regexprep(x, '.sdt', ''), {files.name}, 'UniformOutput', false);
numSessions = length(session_names);
%% Append Information to paramSet
save(sprintf('%s/paramSet.mat', main_dir), 'session_names', 'numSessions', '-append');