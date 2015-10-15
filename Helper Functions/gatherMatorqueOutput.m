function [out, diaryLog] = gatherMatorqueOutput(job)
fprintf('\nGathering job outputs...\n');
out = cellfun(@(x) x.output, job.tasks, 'UniformOutput' , false);
out = cat(1, out{:});

diaryLog = cellfun(@(x) x.diary, job.tasks, 'UniformOutput' , false);
end
