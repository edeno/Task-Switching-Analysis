% makefile.m script -- serves as input template for make.m
% Make appropriate changes to suit your own app

%%1 Main program - either interface myStandalone or myApp
main = 'myStandalone'; % or myApp if not to use myStandalone
                       % Then, place myApp.m in current folder

%%2 Location of the rest of your m-files
srcFolder = '';              % no more files need be compiled
srcFolder = 'codes2compile'; % more files to compile live here

%%3 Your executable base name
exec = 'myExec';   % MATLAB release appended later

%%4 Example needs only Parallel Computing Toolbox (distcomp)
boxes = {};  % default: no toolboxes (other than MATLAB)
%% select 'all' to compile with ALL available toolboxes
%boxes = [boxes, {'all'}];         % MATLAB and all toolboxes
%boxes = [boxes, {'bioinfo'}];     % Bioinformatics_Toolbox
%boxes = [boxes, {'comm'}];        % Communication_Toolbox
%boxes = [boxes, {'curvefit'}];    % Curve_Fitting_Toolbox
boxes = [boxes, {'distcomp'}];    % Distrib_Computing_Toolbox
%boxes = [boxes, {'econ'}];        % Econometrics_Toolbox
%boxes = [boxes, {'finance'}];     % Finance_Toolbox
%boxes = [boxes, {'map'}];         % MAP_Toolbox
%boxes = [boxes, {'optim'}];       % Optimization_Toolbox
%boxes = [boxes, {'stats'}];       % Statistics_Toolbox

runopts = {};   % by default, no runtime options
%%5 Batch runtime options set (prepend with % to de-select)
runopts = [runopts, {'-singleCompThread'}]; % single thread
runopts = [runopts, {'-nodisplay'}];  % no graphics display

%%6 What to display when running standalone executable
credit = '-R ''-startmsg,Program authored by RESEARCHER''';

%% Kadin Tseng & Keith Ma
%% Research Computing Services, Boston University
%% Created:  September, 2014
%% Modified: October, 2014
%%           November, 2014
%%           January, 2015
%%           April, 2015
