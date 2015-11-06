clear variables; clc;
ridgeLambda = 1;
smoothLambda = 0;
numFolds = 1;
isOverwrite = true;
includeTimeBeforeZero = false;
timePeriods = {'Rule Response'};
model = {...
    'Constant', ...
    'Previous Error + Response Direction', ...
    'Previous Error + Response Direction + Rule Repetition', ...
    'Previous Error + Response Direction + Indicator Prep Time', ...
    'Previous Error + Response Direction + Congruency History', ...
    'Previous Error + Response Direction + Rule', ...
    };

runGAMfit;