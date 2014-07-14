% Find all the finished jobs and delete them
% cleanupClusterJob(jobMan, username, state)
% jobMan: job manager
% state: 'finished', 'running', 'queued'
function cleanupClusterJob(jobMan, username, state)

% Find all the finished jobs and delete them
finishedJobs = findJob(jobMan,'State',state,'Username', username);
delete(finishedJobs);

end