clear variables; clc;
ridgeLambda = 1;
smoothLambda = 10.^(-3:4);
numFolds = 5;
isOverwrite = false;
timePeriods = {'Rule Response'};
includeTimeBeforeZero = true;
model = {...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50)', ...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50)', ...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Indicator Prep Time, Trial Time, knotDiff=50)', ...
    's(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50)', ...
    's(Previous Error, Trial Time, knotDiff=50, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50, knotDiff=50) + s(Rule, Trial Time, knotDiff=50, knotDiff=50)', ...
    };

runGAMfit;