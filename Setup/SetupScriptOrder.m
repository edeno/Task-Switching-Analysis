%% Setup Script Order
clear all; close all; clc;

%% Setup Data
setMainDir; % Defines main directory
SetupData; %  Sets up folders
% Need to transfer raw data into raw data folder
SetupSessionNames; % Sets up data names
SetupCovariates; % Sets up covariate names

%% Extract Behavior
ExtractBehavior; % Extracts behavior

%% Extract Spikes
ExtractSpikes;
ExtractGLMCov;