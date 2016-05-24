clear variables; clc;
load('behavior.mat');
load('paramSet.mat', 'sessionNames');
isCC = cellfun(@(x) ~isempty(x), regexp(sessionNames, 'cc*'));
avgCorrectFirstRep = nan(size(behavior));
avgCorrectAfterError = nan(size(behavior));
for session_ind = 1:length(behavior),
    map = behavior{session_ind};
    firstRep = ismember(map('Rule Repetition'), 1);
    firstAfterError = ismember(map('Previous Error'), 2);
    correct = map('Correct');
    avgCorrectFirstRep(session_ind) = nanmean(correct(firstRep));
    avgCorrectAfterError(session_ind) = nanmean(correct(firstAfterError));
end

quantile(avgCorrectFirstRep(isCC), [0.25 .5 0.75])
quantile(avgCorrectFirstRep(~isCC), [0.25 .5 0.75])

quantile(avgCorrectAfterError(isCC), [0.25 .5 0.75])
quantile(avgCorrectAfterError(~isCC), [0.25 .5 0.75])