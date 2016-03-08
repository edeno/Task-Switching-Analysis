clear variables;
numSim = 1000;
numSamples = [];
overwrite = false;
timePeriods = {'Rule Response'};
walltime = '24:00:00';
mem = '80GB';
numCores = 12;
model = {...
    'Rule * Previous Error + Response Direction + Rule * Rule Repetition + Congruency', ...
    };

runAPC;