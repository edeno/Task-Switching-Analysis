%% Setup Script Order
clear variables; clc;
isLocal = true; % on local computer or cluster?
%% Setup Data
SetupData; %  Sets up folders
SetupCovariates; % Sets up covariate names
% Need to transfer raw data into raw data folder
SetupSessionNames; % Sets up data names
%% Extract Behavior
ExtractBehavior(isLocal); % Extracts behavior
%% Extract Spikes
ExtractSpikes(isLocal);
ExtractGLMCov(isLocal);