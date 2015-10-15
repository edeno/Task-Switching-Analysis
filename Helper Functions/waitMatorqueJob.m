function waitMatorqueJob(job, varargin)

inParser = inputParser;
inParser.addRequired('job', @isobject);
inParser.addParameter('timeout', inf, @(x) x > 0 && isnumeric(x)); % in seconds
inParser.addParameter('pauseTime', 60, @(x) x > 0 && isnumeric(x)); % in seconds

inParser.parse(job, varargin{:});

timeout = inParser.Results.timeout;
pauseTime = inParser.Results.pauseTime;

try
    startTime = tic;
    fprintf('Waiting for %s to finish...\n', job.dir);
    while true
        % Lets check if we have already reached or gone beyond the requested state
        isDone = strcmp(job.status, 'done');
        if isDone
             fprintf('\t...Job finished!\n');
            break;
        elseif toc(startTime) > timeout
             break;
             fprintf('\tJob exceeded timeout, %d!\n', timeout);
        end
        pause(pauseTime);
    end
catch err
    % The job object might become invalid during the waitForEvent. Only
    % bother with errors if the job is still valid
    if ishandle(job)
        rethrow(err);
    end
end
end