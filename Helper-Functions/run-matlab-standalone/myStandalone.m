function myStandalone(n, nprocs)
% function myStandalone(n, nprocs)
% Purpose: this optionally serves as the front m-file
%          to your app so your app remain unchanged.
% n: size of arithmetic sequence [1+2+3+ . . . +n]
% nprocs: # of procs [ (matlabpool('local', nprocs) ]
% Standalone Main Program Rules
% a) It must be a function, and it must not have output
%    >> myStandalone 2000 4       % command  syntax
%    >> myStandalone(2000, 4)     % function syntax
% b) The standalone runs in command syntax only 
%    scc1$ ./myExecR2013a 2000 4
% c) Commandline input (if any) are passed as strings
%    Must be converted to double for used as double

% In command syntax, both n and nprocs are strings
if ischar(n) == 1
    disp('n needs conversion')
    n = str2double(n);  % convert string to double
end
if ischar(nprocs) == 1
    disp('nprocs needs conversion')
    nprocs = str2double(nprocs);  % convert string
end

% Call user app, myApp (script or function m-file)
s = myApp(n, nprocs);

% Handle the output (s) as intended
disp(['Sum of Arithmetic sequence 1+2+3+...+n = ' num2str(s)])

if isdeployed     % in standalone mode . . .
   exit;
else
   close all
end

end   % end of function
