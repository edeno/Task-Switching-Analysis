clear all; close all; clc;
isNormalized = false;
apc_type = 'apc';

valid_models = {'Rule * Switch History + Rule * Previous Error History Indicator + Rule * Previous Congruency', ...
    'Rule * Switch History + Rule * Previous Error History Indicator + Rule * Congruency History + Response Direction + Rule * Normalized Prep Time'};

[apc, timePeriods] = apcPlot_process3(apc_type, isNormalized, valid_models);
