close all; clear all; clc;

main_dir = '/data/home/edeno/Task Switching Analysis';
timePeriod = 'Rule Response';
model_name = 'Rule * Switch History + Rule * Previous Error History + Rule * Congruency History + Response Direction + Normalized Prep Time';
overwrite = true;
saveFigs = true;
firing_limit = 0.5;

%% Switch History
covariate_type = 'Switch';

xticklabel_names = {'1', '2', '3', '4' '5', '6', '7', '8', '9', '10', '11+'};
xticks = 1:11;
xlabel_name = 'Number of Trials from Switch';

norm_apcPlot(main_dir, timePeriod, model_name, covariate_type, ...
    'firing_limit', firing_limit, ...
    'xticklabel_names', xticklabel_names, ...
    'xticks', xticks, ...
    'xlabel_name', xlabel_name, ...
    'saveFigs', saveFigs, ...
    'overwrite', overwrite);

%% Error History
covariate_type = 'PrevError';

xticklabel_names = {'1', '2', '3', '4' '5', '6', '7', '8', '9', '10'};
xticks = 1:10;
xlabel_name = 'Number of Trials from Error';

norm_apcPlot(main_dir, timePeriod, model_name, covariate_type, ...
    'firing_limit', firing_limit, ...
    'xticklabel_names', xticklabel_names, ...
    'xticks', xticks, ...
    'xlabel_name', xlabel_name, ...
    'saveFigs', saveFigs, ...
    'overwrite', overwrite);

%% Congruency History

covariate_type = 'Congruency';

xticklabel_names = {'Current', 'Previous'};
xticks = 1:2;
xlabel_name = '';

norm_apcPlot(main_dir, timePeriod, model_name, covariate_type, ...
    'firing_limit', firing_limit, ...
    'xticklabel_names', xticklabel_names, ...
    'xticks', xticks, ...
    'xlabel_name', xlabel_name, ...
    'saveFigs', saveFigs, ...
    'overwrite', overwrite);

%% Rule

covariate_type = 'Rule';

xticklabel_names = {'Rule'};
xticks = 1;
xlabel_name = '';

norm_apcPlot(main_dir, timePeriod, model_name, covariate_type, ...
    'firing_limit', firing_limit, ...
    'xticklabel_names', xticklabel_names, ...
    'xticks', xticks, ...
    'xlabel_name', xlabel_name, ...
    'saveFigs', saveFigs, ...
    'overwrite', overwrite);

%% Response Direction

covariate_type = 'ResponseDir';

xticklabel_names = {'Response Direction'};
xticks = 1;
xlabel_name = '';

norm_apcPlot(main_dir, timePeriod, model_name, covariate_type, ...
    'firing_limit', firing_limit, ...
    'xticklabel_names', xticklabel_names, ...
    'xticks', xticks, ...
    'xlabel_name', xlabel_name, ...
    'saveFigs', saveFigs, ...
    'overwrite', overwrite);

%% Rule x Switch History
covariate_type = 'RuleSwitch';

xticklabel_names = {'1', '2', '3', '4' '5', '6', '7', '8', '9', '10', '11+'};
xticks = 1:11;
xlabel_name = 'Number of Trials from Switch';
excluded_sessions = {'cc1', 'cc3', 'cc4', 'cc5', 'cc6', 'cc7', 'isa2'};
% excluded_sessions = {''};

norm_apcPlot(main_dir, timePeriod, model_name, covariate_type, ...
    'firing_limit', firing_limit, ...
    'xticklabel_names', xticklabel_names, ...
    'xticks', xticks, ...
    'xlabel_name', xlabel_name, ...
    'saveFigs', saveFigs, ...
    'excluded_sessions', excluded_sessions, ...
    'overwrite', overwrite);

%% Rule x Error History
covariate_type = 'RulePrevError';

xticklabel_names = {'1', '2', '3', '4' '5', '6', '7', '8', '9', '10'};
xticks = 1:10;
xlabel_name = 'Number of Trials from Error';
excluded_sessions = {'cc1', 'cc7', 'isa2'};

norm_apcPlot(main_dir, timePeriod, model_name, covariate_type, ...
    'firing_limit', firing_limit, ...
    'xticklabel_names', xticklabel_names, ...
    'xticks', xticks, ...
    'xlabel_name', xlabel_name, ...
    'saveFigs', saveFigs, ...
    'excluded_sessions', excluded_sessions, ...
    'overwrite', overwrite);

%% Rule x Error History Low
covariate_type = 'RulePrevError_low';

xticklabel_names = {'1', '2', '3', '4' '5', '6', '7', '8', '9', '10'};
xticks = 1:10;
xlabel_name = 'Number of Trials from Error';
excluded_sessions = {'cc1', 'cc7', 'isa2'};

norm_apcPlot(main_dir, timePeriod, model_name, covariate_type, ...
    'firing_limit', firing_limit, ...
    'xticklabel_names', xticklabel_names, ...
    'xticks', xticks, ...
    'xlabel_name', xlabel_name, ...
    'saveFigs', saveFigs, ...
    'excluded_sessions', excluded_sessions, ...
    'overwrite', overwrite);

%% Rule x Congruency History

covariate_type = 'RuleCongruency';

xticklabel_names = {'Current', 'Previous'};
xticks = 1:2;
xlabel_name = '';

norm_apcPlot(main_dir, timePeriod, model_name, covariate_type, ...
    'firing_limit', firing_limit, ...
    'xticklabel_names', xticklabel_names, ...
    'xticks', xticks, ...
    'xlabel_name', xlabel_name, ...
    'saveFigs', saveFigs, ...
    'overwrite', overwrite);

%% Rule x Congruency History Low

covariate_type = 'RuleCongruency_low';

xticklabel_names = {'Current', 'Previous'};
xticks = 1:2;
xlabel_name = '';

norm_apcPlot(main_dir, timePeriod, model_name, covariate_type, ...
    'firing_limit', firing_limit, ...
    'xticklabel_names', xticklabel_names, ...
    'xticks', xticks, ...
    'xlabel_name', xlabel_name, ...
    'saveFigs', saveFigs, ...
    'overwrite', overwrite);