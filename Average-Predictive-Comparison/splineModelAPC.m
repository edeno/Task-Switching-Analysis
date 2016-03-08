clear variables;
numSim = 1000;
numSamples = [];
overwrite = false;
timePeriods = {'Rule Response'};
walltime = '24:00:00';
mem = '90GB';
numCores = 12;
model = {...
    '"s(Rule * Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule * Rule Repetition, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50)', ...
    };

runAPC;