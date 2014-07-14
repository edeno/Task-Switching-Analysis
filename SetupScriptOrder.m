%% Setup Script Order
clear all; close all; clc;

%% Setup Data
SetupData; %  Sets up folders
% Need to transfer raw data into raw data folder
SetupSessionNames; % Sets up data names
SetupCovariates; % Sets up covariate names

%% Extract Behavior
ExtractBehavior; % Extracts behavior
BehaviorAnalaysis_timing; % Extracts behavior timing

%% Extract Spikes
ExtractSpikes;
ExtractGLMCov;