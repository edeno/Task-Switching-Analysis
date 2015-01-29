apc_type = 'norm_apc';

valid_models = {'Rule * Switch History + Rule * Previous Error + Rule * Previous Congruency', ...
    'Rule * Switch History + Rule * Previous Error + Rule * Congruency History + Previous Error * Response Direction + Rule * Normalized Prep Time'};

apcToJSON(apc_type, valid_models);
apcToJSON_RuleBy(apc_type, valid_models);
