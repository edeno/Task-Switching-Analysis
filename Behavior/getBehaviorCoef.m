
function [parEst, dev, stats, gam] = getBehaviorCoef(model, varargin)
main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), 'covInfo');
load(sprintf('%s/Behavior/behavior.mat', main_dir));
behavior = mergeMap(behavior);

inParser = inputParser;
inParser.addRequired('model', @ischar);
inParser.addParameter('subject', 'All');
inParser.addParameter('sessionName', 'All');
inParser.addParameter('correctTrialsOnly', false);
inParser.parse(model, varargin{:});
params = inParser.Results;

monkey = bsxfun(@or, strcmpi({params.subject}, behavior('Monkey')), strcmpi(params.subject, 'All'));
sessions = bsxfun(@or, strcmpi({params.sessionName}, behavior('Session Name')), strcmpi(params.sessionName, 'All'));
filter_ind = monkey & sessions;
if params.correctTrialsOnly,
    filter_ind = filter_ind & behavior('Correct');
end

[designMatrix, gam] = gamModelMatrix(model, behavior, covInfo, 'level_reference', 'Reference');
designMatrix = designMatrix(filter_ind, :);

% Correct
correct = double(behavior('Correct'));
correct = correct(filter_ind);
sessionNames = behavior('Session Name');
sessionNames = sessionNames(filter_ind);
sessionNameKeys = unique(sessionNames);

[parEst, dev, stats] = glmfit(designMatrix, correct, 'binomial','link','logit', 'constant', 'off');
end