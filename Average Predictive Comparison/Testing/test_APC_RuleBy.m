session_name = 'cc1';
timePeriod = 'Intertrial Interval';
model_name = 'Rule * Switch History + Rule * Previous Error History + Rule * Previous Congruency';
by_name = 'Previous Error History';
numSim = 100;
numSamples = 100;
save_folder = '';
main_dir = '/data/home/edeno/Task Switching Analysis';

[avpred] = avrPredComp_RuleBy(session_name, timePeriod, model_name, by_name, numSim, numSamples, save_folder, main_dir);

%%

session_name = 'cc1';
timePeriod = 'Intertrial Interval';
model_name = 'Rule * Switch History + Rule * Previous Error History + Rule * Previous Congruency';
by_name = 'Switch History';
numSim = 100;
numSamples = 100;
save_folder = '';
main_dir = '/data/home/edeno/Task Switching Analysis';

[avpred] = avrPredComp_RuleBy(session_name, timePeriod, model_name, by_name, numSim, numSamples, save_folder, main_dir);

%%

session_name = 'cc1';
timePeriod = 'Intertrial Interval';
model_name = 'Rule * Switch History + Rule * Previous Error History + Rule * Previous Congruency';
by_name = 'Normalized Prep Time';
numSim = 100;
numSamples = 100;
save_folder = '';
main_dir = '/data/home/edeno/Task Switching Analysis';

[avpred] = avrPredComp_RuleBy(session_name, timePeriod, model_name, by_name, numSim, numSamples, save_folder, main_dir);
