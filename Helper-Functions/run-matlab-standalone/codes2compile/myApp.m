function s = myApp(n, nslots)
% function s = myApp(n, nslots)
% Purpose: runs basic MATLAB commands to simulate user code for a standalone demo
%       n: size of arithmetic sequence [1+2+3+ . . . +n]
%  nslots: number of processors in parallel computing

% Compute with the Parallel Computing Toolbox
fprintf(1,'\n Test the parallel computing toolbox . . . . .\n');
fprintf(1,'Parfor will be used to compute the sum of the arithmetic sequence\n');
fprintf(1,'s = 1 + 2 + 3 + . . . + n = n(n+1)/2\n\n');
fprintf(1,'Will use %d threads for parfor operations.\n', nslots);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Especially important for running multiple batch jobs
% Without this procedure, some batch jobs may fail 
% redirects ~/.matlab PCT temp files to system's TMPDIR on compute
% node to avoid inter-node (compute node <--> login node) I/O
myCluster = parcluster('local'); % cores on compute node are "local"
if getenv('ENVIRONMENT')         % true if this is a batch job
  myCluster.JobStorageLocation = getenv('TMPDIR')  % points to TMPDIR
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%parpool(myCluster, nslots);      % MATLAB R2014a or newer
matlabpool(myCluster, nslots);    % MATLAB R2013b or older
% REPLACE BELOW EXAMPLE WITH YOUR APP
% This example uses parfor to compute arithmetic sequence sum
s = 0;             % initialize sequence sum s
parfor i=1:n
    s = s + i;     % s = 1 + 2 + 3 + . . . + n
end
matlabpool close;  % MATLAB R2013 or older
%delete(gcp)       % MATLAB R2014 or newer

fprintf(1,'\n\n Iteration count n = %d\n', n);
fprintf(1,'\nComputed s = %d   ;  Expected s =  %d \n\n', s, n*(n+1)/2);

end   % end of function 

