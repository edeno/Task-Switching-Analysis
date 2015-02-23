jobMan = parcluster();
finishedJobs = findJob(jobMan, 'State', 'finished', 'Username', 'edeno');
numJobs = length(finishedJobs);

isError = false(1, numJobs);
error_message = cell(1, numJobs);

for job_ind =  1:numJobs,
   isError(job_ind) = ~strcmp(finishedJobs(job_ind).Tasks(1).ErrorMessage, '');
   if isError(job_ind),
       error_message{job_ind} = finishedJobs(job_ind).Tasks(1).ErrorMessage;
   end
end

display(find(isError));
error_message{isError}
if sum(isError) == 0,
   fprintf('No Errors!'); 
end