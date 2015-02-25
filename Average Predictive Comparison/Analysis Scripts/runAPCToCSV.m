apc_type = 'norm_apc';

valid_models = {'Rule * Rule Repetition + Rule * Previous Error + Rule * Previous Congruency + Session Time', ...
    'Rule * Rule Repetition + Rule * Previous Error + Rule * Congruency History + Previous Error * Response Direction + Rule * Indicator Prep Time + Session Time'};

apcToCSV(apc_type, valid_models);
apcToCSV_RuleBy(apc_type, valid_models);
