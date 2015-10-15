function [out] = gatherMatorqueOutput(job)
fprintf('\nGathering job outputs...\n');
out = cellfun(@(x) x.output, job.tasks, 'UniformOutput' , false);
out = cat(1, out{:});
end