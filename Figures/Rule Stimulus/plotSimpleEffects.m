timePeriods = {'Rule Stimulus', 'Stimulus Response'};

for time_ind = 1:length(timePeriods),
    % Rule
    comparisonName = 'Orientation - Color';
    plotPermutationAnalysis(comparisonName, timePeriods{time_ind});
    
    model = 'Rule';
    plotIndividualPred(model, timePeriods{time_ind});
    
    % Previous Error
    comparisonName = 'Previous Error - No Previous Error';
    plotPermutationAnalysis(comparisonName, timePeriods{time_ind});
    
    model = 'Previous Error';
    plotIndividualPred(model, timePeriods{time_ind});
    
    % Rule Repetitions
    comparisonName = 'Repetition1 - Repetition5+';
    plotPermutationAnalysis(comparisonName, timePeriods{time_ind});
    
    comparisonName = 'Repetition2 - Repetition5+';
    plotPermutationAnalysis(comparisonName, timePeriods{time_ind});
    
    comparisonName = 'Repetition3 - Repetition5+';
    plotPermutationAnalysis(comparisonName, timePeriods{time_ind});
    
    comparisonName = 'Repetition4 - Repetition5+';
    plotPermutationAnalysis(comparisonName, timePeriods{time_ind});
    
    model = 'Rule Repetition';
    plotIndividualPred(model, timePeriods{time_ind});
    
    % Conguency
    if strcmp(timePeriods{time_ind}, 'Stimulus Response'),
        comparisonName = 'Incongruent - Congruent';
        plotPermutationAnalysis(comparisonName, timePeriods{time_ind});
    end
    
    % Interactions
    comparisonName = 'Orientation Rule - Color Rule @ Previous Error';
    plotPermutationAnalysis(comparisonName, timePeriods{time_ind});
    
    comparisonName = 'Orientation Rule - Color Rule @ Repetition1';
    plotPermutationAnalysis(comparisonName, timePeriods{time_ind});
    
    comparisonName = 'Orientation Rule - Color Rule @ Repetition2';
    plotPermutationAnalysis(comparisonName, timePeriods{time_ind});
    
    comparisonName = 'Orientation Rule - Color Rule @ Repetition3';
    plotPermutationAnalysis(comparisonName, timePeriods{time_ind});
    
    comparisonName = 'Orientation Rule - Color Rule @ Repetition4';
    plotPermutationAnalysis(comparisonName, timePeriods{time_ind});
end

%% Compare predictions of simple effects

models = {'Rule','Previous Error','Rule Repetition'};
plotCompareModels(models,  timePeriods{1});

models = {'Rule','Previous Error','Rule Repetition', 'Congruency'};
plotCompareModels(models,  timePeriods{2});

%% Compare Additive Models
for time_ind = 1:length(timePeriods),
    models = { ...
        'Rule + Previous Error', 'Rule + Rule Repetition', 'Rule + Previous Error + Rule Repetition', 'Previous Error + Rule Repetition', ...
        };
    plotCompareModels(models,  timePeriods{time_ind});
end

%% Compare Additive models with simple effects
for time_ind = 1:length(timePeriods),
    models = {'Rule','Previous Error','Rule Repetition', ...
        'Rule + Previous Error', 'Rule + Rule Repetition', 'Rule + Previous Error + Rule Repetition', 'Previous Error + Rule Repetition', ...
        };
    plotCompareModels(models,  timePeriods{time_ind});
end

%%
for time_ind = 1:length(timePeriods),
    models = {'Rule','Previous Error','Rule Repetition', ...
        'Rule + Previous Error', 'Rule + Rule Repetition', 'Rule + Previous Error + Rule Repetition', 'Previous Error + Rule Repetition', ...
        'Rule * Previous Error + Rule Repetition', 'Previous Error + Rule * Rule Repetition', ...
        'Rule * Previous Error', 'Rule * Rule Repetition', ...
        'Rule * Previous Error + Rule * Rule Repetition'};
    plotCompareModels(models,  timePeriods{time_ind});
end
