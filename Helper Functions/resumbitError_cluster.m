% Note: does not work with current version of matlab on cluster R2013b
% need matlab 2014a or greater
jobMan = parcluster();
failedJobs = findJob(jobMan,'Username','edeno','State','failed');
numJobs = length(failedJobs);
newJob = cell(1, numJobs);

for job_ind = 1:numJobs,
    newJob{job_ind} = recreate(failedJobs(job_ind));
    submit(newJob{job_ind});
end

