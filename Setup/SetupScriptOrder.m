%% Setup Script Order
clear variables; clc;

%% Setup Data
SetupData; %  Sets up folders
SetupCovariates; % Sets up covariate names
% Need to transfer raw data into raw data folder
SetupSessionNames; % Sets up data names
%% Extract Behavior
ExtractBehavior; % Extracts behavior

%% Extract Spikes
ExtractSpikes;
ExtractGLMCov;