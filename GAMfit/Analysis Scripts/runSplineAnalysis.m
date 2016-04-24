clear variables;
timePeriods = {'Rule Stimulus', ...
    'Stimulus Response'};
models = {'s(Rule, Trial Time, knotDiff=50) + s(Previous Error, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50)', ...
    's(Rule, Trial Time, knotDiff=50) + s(Previous Error, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50)'};
subjects = {'cc', 'isa'};
brainAreas = {'ACC', 'dlPFC'};

for model_ind = 1:length(models),
    for subject_ind = 1:length(subjects),
        for area_ind = 1:length(brainAreas),
            plotSplinePopFit(models{model_ind}, timePeriods{model_ind}, 'subject', subjects{subject_ind}, 'brainArea', brainAreas{area_ind})
        end
    end
end