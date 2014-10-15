jobMan = parcluster();
finishedJobs = findJob(jobMan, 'State', 'finished', 'Username', 'edeno');

for job_ind = 1:length(finishedJobs),
    
    errorTasks = [finishedJobs(job_ind).Tasks];
    error_message = {errorTasks.ErrorMessage};
    isError = ~strcmp(error_message, '');
    if any(isError),
        
        errorJobs = finishedJobs(job_ind);
        
        fprintf('\n Resubmitting Job ID: %d \n', errorJobs.ID);
        if ~strcmp(errorJobs.Type, 'independent'),
            newJob = createCommunicatingJob(jobMan, 'AdditionalPaths', errorJobs.AdditionalPaths, 'AttachedFiles', ...
                errorJobs.AttachedFiles, 'NumWorkersRange', errorJobs.NumWorkersRange, 'Type', errorJobs.Type);
            task_id = find(isError);
            for task_ind = 1:length(task_id),
                createTask(newJob, ...
                    errorJobs.Tasks(task_id(task_ind)).Function, ...
                    errorJobs.Tasks(task_id(task_ind)).NumOutputArguments, ...
                    errorJobs.Tasks(task_id(task_ind)).InputArguments);
            end
            submit(newJob);
        else
            newJob = createJob(jobMan, 'AdditionalPaths', errorJobs.AdditionalPaths, 'AttachedFiles', ...
                errorJobs.AttachedFiles, 'NumWorkersRange', errorJobs.NumWorkersRange);
            task_id = find(isError);
            for task_ind = 1:length(task_id),
                createTask(newJob, ...
                    errorJobs.Tasks(task_id(task_ind)).Function, ...
                    errorJobs.Tasks(task_id(task_ind)).NumOutputArguments, ...
                    errorJobs.Tasks(task_id(task_ind)).InputArguments);
            end
            submit(newJob);
        end
    else
        continue;
    end
end