function runBatchJob(n, nslots)
% computes sum s=1+2+3+...+n=n(n+1)/2 with nslots cores
% redirects ~/.matlab PCT temp files to TMPDIR on the compute
% node to avoid inter-node (compute node <--> login node) I/O

myCluster = parcluster('local') % cores on compute node to be "local"
if getenv('ENVIRONMENT')    % true if this is a batch job
  myCluster.JobStorageLocation = getenv('TMPDIR')  % points to TMPDIR
end

% REPLACE BELOW EXAMPLE WITH YOUR APP (either scripts or functions)
% parpool(myCluster, nslots) % MATLAB R2014 or newew
matlabpool(myCluster, nslots)  % MATLAB R2013 or older
s = 0;
parfor i=1:n
  s = s + i;   % compute s = 1 + 2 + ... + n = n(n+1)/2
end

fprintf(1,'Computed arithmetic sequence sum s = %d', s);
fprintf(1,'  (correct answer: %d)\n\n\n', n*(n+1)/2);

matlabpool close   % MATLAB R2013 or older
% delete(gcp)      % MATLAB R2014 or newer

end

