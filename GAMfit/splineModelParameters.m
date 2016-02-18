clear variables; clc;
ridgeLambda = 1;
smoothLambda = 10.^(-3:4);
numFolds = 5;
isOverwrite = false;
timePeriods = {'Rule Response'};
includeTimeBeforeZero = true;
walltime = '160:00:00';
mem = '124GB';
numCores = 9;

model = {...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50)', ...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50)', ...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50)', ...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50)', ...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule, Trial Time, knotDiff=50)', ...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50) + s(Rule, Trial Time, knotDiff=50)', ...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50) + s(Rule, Trial Time, knotDiff=50)', ...
    's(Rule * Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50)', ...
    's(Rule * Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule * Rule Repetition, Trial Time, knotDiff=50) + s(Rule * Congruency, Trial Time, knotDiff=50)', ...
    };

runGAMfit;