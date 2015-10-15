function waitMatorqueJob(job)
timeout = inf;
try
    startTime = tic;
    fprintf('Waiting for %s to finish', job.dir);
    while true
        % Lets check if we have already reached or gone beyond the requested state
        isDone = strcmp(job.status, 'done');
        if isDone || toc(startTime) > timeout
            break
        end
        pause(1);
    end
catch err
    % The job object might become invalid during the waitForEvent. Only
    % bother with errors if the job is still valid
    if ishandle(job)
        rethrow(err);
    end
end
end