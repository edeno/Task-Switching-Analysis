apc_type = 'norm_apc';

valid_models = {'Rule * Rule Repetition + Rule * Previous Error History + Rule * Previous Congruency + Session Time', ...
    'Rule * Rule Repetition + Rule * Previous Error History + Rule * Congruency History + Previous Error History * Response Direction + Rule * Indicator Prep Time + Session Time'};

apcToCSV(apc_type, valid_models);
apcToCSV_RuleBy(apc_type, valid_models);
