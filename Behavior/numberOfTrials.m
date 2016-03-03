%% Load
clear variables
load('behavior.mat');
load('paramSet.mat', 'covInfo', 'sessionNames');

%% Preallocate
numFiles = length(behavior);
rulePercentage = nan(numFiles, length(covInfo('Rule').levels), 3);
ruleRepetitionPercentage = nan(numFiles, length(covInfo('Rule Repetition').levels), 3);
congruencyPercentage = nan(numFiles, length(covInfo('Congruency').levels), 3);
previousErrorPercentage = nan(numFiles, length(covInfo('Previous Error').levels), 3);
responseDirectionPercentage = nan(numFiles, length(covInfo('Response Direction').levels), 3);
colorRuleRepetitionPercentage = nan(numFiles, length(covInfo('Rule Repetition').levels), 3);
orientationRuleRepetitionPercentage = nan(numFiles, length(covInfo('Rule Repetition').levels), 3);
colorPreviousErrorPercentage = nan(numFiles, length(covInfo('Previous Error').levels), 3);
orientationPreviousErrorPercentage = nan(numFiles, length(covInfo('Previous Error').levels), 3);
numTrials = nan(numFiles, 1);

%% Calculate
for file_ind = 1:numFiles,
    isAttempted = behavior{file_ind}('Attempted');
    isCorrect = behavior{file_ind}('Correct');
    
    keep_ind = isAttempted & isCorrect;
    
    rule = behavior{file_ind}('Rule');
    ruleRepetition = behavior{file_ind}('Rule Repetition');
    congruency = behavior{file_ind}('Congruency');
    previousError = behavior{file_ind}('Previous Error');
    responseDirection = behavior{file_ind}('Response Direction');
    monkeyName = behavior{file_ind}('Monkey');
    
    rule = rule(keep_ind);
    ruleRepetition = ruleRepetition(keep_ind);
    congruency = congruency(keep_ind);
    previousError = previousError(keep_ind);
    responseDirection = responseDirection(keep_ind);
    
    rulePercentage(file_ind, :, :) = tabulate(rule);
    ruleRepetitionPercentage(file_ind, :, :) = tabulate(ruleRepetition);
    congruencyPercentage(file_ind, :, :) = tabulate(congruency);
    previousErrorPercentage(file_ind, :, :) = tabulate(previousError);
    responseDirectionPercentage(file_ind, :, :) = tabulate(responseDirection);
    
    color_ind = (rule == 1);
    orientation_ind = (rule == 2);
    
    colorRuleRepetitionPercentage(file_ind, :, :) = tabulate(ruleRepetition(color_ind));
    orientationRuleRepetitionPercentage(file_ind, :, :) = tabulate(ruleRepetition(orientation_ind));
    
    colorPreviousErrorPercentage(file_ind, :, :) = tabulate(previousError(color_ind));
    orientationPreviousErrorPercentage(file_ind, :, :) = tabulate(previousError(orientation_ind));
    numTrials(file_ind) = sum(keep_ind);
    
end

%% Display
fprintf('Color Rule Previous Errors\n');
fprintf('\tAverage: %d\n', round(mean(colorPreviousErrorPercentage(:, 2, 2))));
fprintf('\tRange: %d %d\n', quantile(colorPreviousErrorPercentage(:, 2, 2), [0, 1]));

fprintf('\nOrientation Rule Previous Errors\n');
fprintf('\tAverage: %d\n', round(mean(orientationPreviousErrorPercentage(:, 2, 2))));
fprintf('\tRange: %d %d\n', quantile(orientationPreviousErrorPercentage(:, 2, 2), [0, 1]));

fprintf('\nColor Rule Switch Trials\n');
fprintf('Color Rule Switchs\n');
fprintf('\tAverage: %d\n', round(mean(colorRuleRepetitionPercentage(:, 1, 2))));
fprintf('\tRange: %d %d\n', quantile(colorRuleRepetitionPercentage(:, 1, 2), [0, 1]));

fprintf('Orientation Rule Previous Errors\n');
fprintf('\tAverage: %d\n', round(mean(orientationRuleRepetitionPercentage(:, 1, 2))));
fprintf('\tRange: %d %d\n', quantile(orientationRuleRepetitionPercentage(:, 1, 2), [0, 1]));

badFiles = sessionNames(any([colorRuleRepetitionPercentage(:, 1, 2), orientationRuleRepetitionPercentage(:, 1, 2)] < 20, 2));
display(badFiles);

isCC = cellfun(@(x) ~isempty(x), strfind(sessionNames, 'cc'));
isISA = ~isCC;
