function make(varargin)
% function make(varargin)
% Purpose: compile standalone with mcc
% Support file: makefile.m (or alternative filename)
% make compiles if executable is older than file(s)
% Usage:
% >> make % compile with makefile(.m)
% >> make filename % compile with filename(.m)
% >> make dryrun % make a dryrun with makefile (show detail)
% >> make filename dryrun % make a dryrun with filename
% >> make dryrun filename % make a dryrun with filename

% Strip filename's file extension (if present)
for i=1:nargin
  [~,name,~] = fileparts(varargin{i}); 
  varargin{i} = name;
end

% param={cmd  file} dictates what make will do & with what
switch nargin
   case 0    % default: compile /with/ makefile
     param = {'compile' 'makefile'}; % default settings
     fprintf('Use default: %s with %s\n', param{1}, param{2});
   case 1    % dryrun /with/ makefile or compile /with/ filename
     if strcmpi('dryrun', varargin)   
       param = {'dryrun' 'makefile'};
     else
       param = {'compile' varargin{1}};
     end
     fprintf('Set 1 parameter: %s with %s\n', param{1}, param{2});
   case 2    % dryrun /with/ filename
     ind = find(~strcmpi('dryrun', varargin));
     param = {'dryrun' varargin{ind}};
     fprintf('Set 2 parameters: %s with %s\n', param{1}, param{2});
   otherwise
     fprintf('Too many input. Process terminated.\n');
     exit
end

dryrun = strcmpi('dryrun', param{1}); % dryrun(true) or compile
run(param{2});   % runs makefile or filename

opts = '-N';   % compile for MATLAB only (no toolboxes)
theMessage = 'compile for MATLAB only (no toolboxes)';
if numel(boxes) > 0
   if sum(cell2mat(strfind(boxes,'all'))) >= 1;
     opts = ''; % compile for MATLAB and all toolboxes
     theMessage = 'compile for MATLAB and all toolboxes';
   else
     opts = strcat({'-p '},boxes,{' '}); % add to each element of boxes
     opts = ['-N ' opts{1:end}];   % looks like this: '-N -p optim -p stats'
     theMessage = 'compile for MATLAB and selected toolboxes';
   end
end

runtimeopts = [];
if numel(runopts) > 0
   runtimeopts = strcat({'-R '}, runopts, {' '});
   runtimeopts = [runtimeopts{1:end}];
end

% Append MATLAB MCR version detail to exec name
r = version;
release = r(end-6:end-1);  % extracts the last chars, e.g., R2013a
myexec = sprintf('%s%s', exec, release);  % exec named myExecR2013a

% Define mcc command string, mymcc, starting with . . .
mymcc = sprintf('mcc -mv -o %s %s ...\n', myexec, main);

% Add compiler options
mymcc = [mymcc sprintf('       %s ...\n', opts)];

% Next, specify the runtime options . . .
if numel(runtimeopts) > 0
  mymcc = [mymcc sprintf('       %s ...\n', runtimeopts)];
end

% Credits due . . .
mymcc = [mymcc sprintf('       %s ... \n', credit)];
% Then add "-a srcFolder" to point to user app files
mymcc = [mymcc sprintf('       -a %s\n', srcFolder)];

fprintf(1,'\n\nmake will %s . . .\n %s\n', theMessage, mymcc)

%% Check if executable exists or outdated
if ~exist(myexec) 
  fprintf('Standalone does not exist !\n');
  go = true;
else
  tmp = [dir(myexec); dir([main '.m']); nodots(srcFolder);];
  tstamp = [tmp.datenum];
  tfiles = tstamp(2:end);
  texec = repmat(tstamp(1), [1, numel(tfiles)]);
  if logical(any((tfiles - texec)>0))
    fprintf('At least 1 file is newer than myexec; compile !\n');
    go = true;
    STR1='File'; STR2='Last Modified';
    fprintf('%-35s %32s\n',STR1, STR2);
    for i=1:numel(tstamp)
      fprintf('%-35s \t %s\n',tmp(i).name,datestr(tstamp(i)));
    end
  else
    fprintf('%s is up-to-date, no compilation required !\n', myexec);
    go = false;
  end
end

if dryrun
  fprintf('\n\n******************************************************\n');
  fprintf(1,'    This is a test. No standalone generated.\n')
  fprintf('******************************************************\n');
else
  if go
    tic   % starts wallclock timer to record compile time
    fprintf('Starts compiling . . .\n');
    eval(mymcc) % run the mcc statement
    fprintf('\n\n******************************************************\n');
    fprintf('Compile time for %s is %8.2f seconds\n', myexec, toc);
    fprintf('******************************************************\n');
  end
end

%% Kadin Tseng & Keith Ma
%% Research Computing Services, Boston University
%% Created:  September, 2014
%% Modified: October, 2014
%%           November, 2014
%%           January, 2015
%%           April, 2015
end   % function

function d = nodots(target)
d = dir(target); % 'target' is the investigated directory
d = d(arrayfun(@(x) ~strcmp(x.name(1),'.'),d)); % remove .
d = d(arrayfun(@(x) ~strcmp(x.name(1),'..'),d));% remove ..
end
