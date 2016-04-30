%% Setup Script Order
clear variables; clc;
isLocal = true; % on local computer or cluster?
%% Setup Data
SetupData; %  Sets up folders
SetupCovariates; % Sets up covariate names
SetupColorOrder; % Maps level names to colors
SetupNeuronInfo; % Maps neuron names to information about neuron
% Need to transfer raw data into raw data folder
SetupSessionNames; % Sets up data names
%% Extract Behavior
ExtractBehavior(isLocal); % Extracts behavior
%% Extract Spikes
ExtractSpikes(isLocal);
ExtractSpikeCovariates(isLocal);