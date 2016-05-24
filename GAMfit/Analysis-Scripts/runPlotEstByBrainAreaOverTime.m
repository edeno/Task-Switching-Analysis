timePeriods = {'Intertrial Interval', ...
    'Fixation', ...
    'Rule Stimulus', ...
    'Stimulus Response', ...
    'Saccade', ...
    'Reward', ...
    };
modelName = {'Rule + Previous Error History', ...
    'Rule + Previous Error History', ...
    'Rule + Previous Error History + Rule Repetition', ...
    'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction', ...
    'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction', ...
    'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction', ...
    };

plotEstByBrainAreaOverTime(modelName, timePeriods)

%%

modelName = {'Rule * Previous Error History + Rule * Rule Repetition', ...
    'Rule * Previous Error History + Rule * Rule Repetition', ...
    'Rule * Previous Error History + Rule * Rule Repetition', ...
    'Rule * Previous Error History + Rule * Rule Repetition + Congruency + Response Direction', ...
    'Rule * Previous Error History + Rule * Rule Repetition + Congruency + Response Direction', ...
    'Rule * Previous Error History + Rule * Rule Repetition + Congruency + Response Direction', ...
    };

plotEstByBrainAreaOverTime(modelName, timePeriods)

%%
modelName = {'Rule + Previous Error History + Session Time', ...
    'Rule + Previous Error History + Session Time', ...
    'Rule + Previous Error History + Rule Repetition + Session Time', ...
    'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction + Session Time', ...
    'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction + Session Time', ...
    'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction + Session Time', ...
    };

plotEstByBrainAreaOverTime(modelName, timePeriods)

%%

modelName = {'Rule * Previous Error History + Session Time', ...
    'Rule * Previous Error History + Session Time', ...
    'Rule * Previous Error History + Rule * Rule Repetition + Session Time', ...
    'Rule * Previous Error History + Rule * Rule Repetition + Congruency + Response Direction + Session Time', ...
    'Rule * Previous Error History + Rule * Rule Repetition + Congruency + Response Direction + Session Time', ...
    'Rule * Previous Error History + Rule * Rule Repetition + Congruency + Response Direction + Session Time', ...
    };

plotEstByBrainAreaOverTime(modelName, timePeriods)

%%

modelName = {'Rule * Previous Error History + Rule * Rule Repetition', ...
    'Rule * Previous Error History + Rule * Rule Repetition', ...
    'Rule * Previous Error History + Rule * Rule Repetition', ...
    'Rule * Previous Error History + Rule * Rule Repetition + Congruency + Response Direction', ...
    'Rule * Previous Error History + Rule * Rule Repetition + Congruency + Response Direction', ...
    'Rule * Previous Error History + Rule * Rule Repetition + Congruency + Response Direction', ...
    };

plotEstByBrainAreaOverTime(modelName, timePeriods, 'isSim', false)