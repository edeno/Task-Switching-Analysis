function [plotHandles] = reactModelCheck(model, varargin)
main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), 'covInfo');
load(sprintf('%s/Behavior/behavior.mat', main_dir));
behavior = mergeMap(behavior);

inParser = inputParser;
inParser.addRequired('model', @ischar);
inParser.addParameter('Monkey', 'All');
inParser.addParameter('Session', 'All');
inParser.addParameter('correctTrialsOnly', false);
inParser.addParameter('Color', 'blue');
inParser.parse(model, varargin{:});
params = inParser.Results;

monkey = bsxfun(@or, strcmpi({params.Monkey}, behavior('Monkey')), strcmpi(params.Monkey, 'All'));
sessions = bsxfun(@or, strcmpi({params.Session}, behavior('Session Name')), strcmpi(params.Session, 'All'));
filter_ind = monkey & sessions;
if params.correctTrialsOnly,
    filter_ind = filter_ind & behavior('Correct');
end

trialNumber = behavior('Trial Number');
trialNumber = [trialNumber{:}]; % Temporary fix until rerun behavior. Need to REMOVE.
trialNumber = trialNumber(filter_ind);
designMatrix = gamModelMatrix(model, behavior, covInfo, 'level_reference', 'Reference');
designMatrix = designMatrix(filter_ind, :);

% Reaction Time
reactionTime = behavior('Reaction Time');
reactionTime = reactionTime(filter_ind);

[parameterEst, ~, stats] = glmfit(designMatrix, reactionTime, 'normal', 'link', 'log', 'constant', 'off');

sessionNames = behavior('Session Name');
sessionNames = sessionNames(filter_ind);
sessionNameKeys = unique(sessionNames);
numSessions = length(sessionNameKeys);
numParameters = size(designMatrix, 2);
parameterEstBySession = nan(numSessions, numParameters);
stats = cell(numSessions, 1);
for session_ind = 1:numSessions,
    sessionID = ismember(sessionNames, sessionNameKeys(session_ind));
    [parameterEstBySession(session_ind, :), ~, stats{session_ind}] = glmfit(designMatrix(sessionID, :), reactionTime(sessionID, :), 'normal', 'link', 'log', 'constant', 'off');
end

stats = [stats{:}];
badNaN_ind = any(isnan(designMatrix), 2) | isnan(reactionTime);

numSim = 500;
simReactionTime = nan(size(reactionTime, 1), numSim);

for session_ind = 1:numSessions,
    paramSim = mvnrnd(parameterEstBySession(session_ind, :), stats(session_ind).covb, numSim)';
    sessionID = ismember(sessionNames, sessionNameKeys(session_ind));
    simReactionTime(sessionID, :) = exp(designMatrix(sessionID, :) * paramSim);
end
% subplotSize = numSubplots(numSim + 1);

subplot(2,2,1);
for plot_ind = 1:(numSim + 1),
    %     subplot(subplotSize(1), subplotSize(2), plot_ind);
    if plot_ind == 1,
        plotHandles{plot_ind} = histogram(reactionTime(~badNaN_ind));
        plotHandles{plot_ind}.DisplayStyle = 'stairs';
        plotHandles{plot_ind}.BinMethod = 'integers';
        plotHandles{plot_ind}.EdgeColor = params.Color;
        plotHandles{plot_ind}.LineWidth = 3;
        %         vline(nanmean(reactionTime), 'Color', params.Color, 'LineType', '-', 'LineWidth', 1);
    else
        plotHandles{plot_ind} = histogram(simReactionTime(~badNaN_ind, plot_ind - 1));
        plotHandles{plot_ind}.DisplayStyle = 'stairs';
        plotHandles{plot_ind}.BinMethod = 'integers';
        plotHandles{plot_ind}.EdgeColor = tintColor(str2RGBColor(params.Color));
        plotHandles{plot_ind}.LineWidth = 0.5;
        plotHandles{plot_ind}.EdgeAlpha = 0.05;
        %         vline(nanmean(simReactionTime(:, plot_ind - 1)), 'Color', params.Color, 'LineType', '-', 'LineWidth', 1);
    end
    hold all;
    ylabel('Count');
    %     xlim([0 400]);
    box off;
end

subplot(2,2,2);
resid = bsxfun(@minus, simReactionTime, reactionTime);
plot(trialNumber, resid, '.', 'Color', params.Color);
xlabel('Trial Number');
ylabel('Residuals');
hold all;
box off;

subplot(2,2,3);
resid = cat(1, stats.resid);
plot(exp(designMatrix * parameterEst), resid, '.', 'Color', params.Color);
hold all;
ylabel('Residuals');
xlabel('Fitted Values');

box off;

subplot(2,2,4);
plot(resid(1:end-1), resid(2:end), '.', 'Color', params.Color);
hold all;
xlabel('Residuals k');
ylabel('Residuals (k-1)');
box off;
end