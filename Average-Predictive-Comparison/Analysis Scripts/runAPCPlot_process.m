clear all; close all; clc;
isNormalized = true;
apc_type = 'apc';
monkey = 'All';
baseline_bounds = [0.5 1000];

valid_models = {'Rule * Switch History + Rule * Previous Error History + Rule * Previous Congruency', ...
    'Rule * Switch History + Rule * Previous Error History + Rule * Congruency History + Response Direction + Rule * Normalized Prep Time'};

[apc] = apcPlot_process(apc_type, isNormalized, valid_models, monkey, baseline_bounds);

% apcPloting(apc);
apcPloting_simple(apc)