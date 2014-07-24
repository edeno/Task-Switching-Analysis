jobMan = parcluster();
finishedJobs = findJob(jobMan, 'State', 'finished', 'Username', 'edeno');

errorTasks = [finishedJobs.Tasks];
error_message = {errorTasks(1, :).ErrorMessage};
isError = ~strcmp(error_message, '');

errorJobs = finishedJobs(isError);

numNewJobs = length(errorJobs);
newJob = cell(1, numNewJobs);

for job_ind = 1:numNewJobs,
    fprintf('\n Resubmitting Job ID: %d \n', errorJobs(job_ind).ID);
    newJob{job_ind} = createCommunicatingJob(jobMan, 'AdditionalPaths', errorJobs(job_ind).AdditionalPaths, 'AttachedFiles', ...
        errorJobs(job_ind).AttachedFiles, 'NumWorkersRange', errorJobs(job_ind).NumWorkersRange, 'Type', errorJobs(job_ind).Type);
    
    createTask(newJob{job_ind}, errorJobs(job_ind).Tasks(1).Function, errorJobs(job_ind).Tasks(1).NumOutputArguments, errorJobs(job_ind).Tasks(1).InputArguments);
    submit(newJob{job_ind});
end