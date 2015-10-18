clear variables; clc;
ridgeLambda = 1;
smoothLambda = 10.^(-3:4);
numFolds = 5;
isOverwrite = true;
timePeriods = {'Rule Response'};
includeTimeBeforeZero = true;
model = {...
    's(Previous Error, Trial Time) + s(Response Direction, Trial Time)', ...
    's(Previous Error, Trial Time) + s(Response Direction, Trial Time) + s(Rule Repetition, Trial Time)', ...
    's(Previous Error, Trial Time) + s(Response Direction, Trial Time) + s(Indicator Prep Time, Trial Time)', ...
    's(Previous Error, Trial Time) + s(Response Direction, Trial Time) + s(Congruency History, Trial Time)', ...
    's(Previous Error, Trial Time) + s(Response Direction, Trial Time) + s(Rule, Trial Time)', ...
    };

runGAMfit;