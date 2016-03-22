%% Setup Data Parameters
% Define main data directory
main_dir = getWorkingDir();
% Make main
if ~exist(main_dir, 'dir')
    mkdir(main_dir);
end

% Define sub-directories
dataInfo.script_dir = sprintf('%s/Matlab Scripts', main_dir);
dataInfo.processed_dir = sprintf('%s/Processed Data', main_dir);
dataInfo.behavior_dir = sprintf('%s/Behavior', main_dir);
dataInfo.manuscript_dir = sprintf('%s/Manuscript', main_dir);
dataInfo.figure_dir = sprintf('%s/Figures', main_dir);
dataInfo.rawData_dir = sprintf('%s/Raw Data', main_dir);

% Make sub-directories
dataFieldNames = fieldnames(dataInfo);
for data_ind = 1:length(dataFieldNames),
    if ~exist(dataInfo.(dataFieldNames{data_ind}), 'dir'),
        mkdir(dataInfo.(dataFieldNames{data_ind}));
    end
end

%% Setup Encode Parameters
% Trial Time Parameters
trialInfo = containers.Map;
trialInfo('Start Trial Encode') = 9;
trialInfo('Fixation ON Encode') = 35;
trialInfo('Fixation ACQUIRED Encode') = 8;
trialInfo('Rule ON Encode') = 29;
trialInfo('Test Stimulus ON Encode') = 23;
trialInfo('Saccade START Encode') = 44;
trialInfo('Saccade FIXATION Encode') = 45;
trialInfo('Reward Encode') = 4;
trialInfo('No Reward Encode') = 5;
trialInfo('Reward START Encode') = [trialInfo('Reward Encode'), trialInfo('No Reward Encode')];
trialInfo('End Trial Encode') = 18;

% Condition Parameters
trialInfo('Rule Cues:Color Cue1') = [0 1 4 5 16 17 20 21]; %16 6 Cue4.bmp 26 x 36 Black sq
trialInfo('Rule Cues:Color Cue2') = [2 3 6 7 18 19 22 23]; %6 Only 26 x 36 black sq
trialInfo('Rule:Color') = [trialInfo('Rule Cues:Color Cue1'), trialInfo('Rule Cues:Color Cue2')];
trialInfo('Rule Cues:Orientation Cue1') = [8 9 12 13 24 25 28 29]; %15 6 Cue3.bmp(w/black)
trialInfo('Rule Cues:Orientation Cue2') = [10 11 14 15 26 27 30 31]; %5 6 37 x 49 Pink Sq 26 x 36 Black sq
trialInfo('Rule:Orientation') = [trialInfo('Rule Cues:Orientation Cue1'), trialInfo('Rule Cues:Orientation Cue2')];
trialInfo('Test Stimulus:Vertical Blue') = [16 18 24 26 20 22 28 30];
trialInfo('Test Stimulus:Vertical Red') = [0 2 8 10 4 6 12 14];
trialInfo('Test Stimulus:Horizontal Blue') = [1 3 9 11 5 7 13 15];
trialInfo('Test Stimulus:Horizontal Red') = [17 19 25 27 21 23 29 31];
trialInfo('Congruency:Congruent') = [trialInfo('Test Stimulus:Vertical Blue'), trialInfo('Test Stimulus:Horizontal Red')];
trialInfo('Congruency:Incongruent') = [trialInfo('Test Stimulus:Vertical Red'), trialInfo('Test Stimulus:Horizontal Blue')];
trialInfo('Saccade:Right') = [0 9 2 11 4 13 6 15 17 25 19 27 21 29 23 31];
trialInfo('Saccade:Left') = [1 3 5 7 8 10 12 14 16 18 20 22 24 26 28 30];
trialInfo('Correct') = 0;
trialInfo('Incorrect') = 6;
trialInfo('Fixation Break') = [3 4];

monkeyNames = {'CC', 'CH', 'ISA'};
validPredType = {'Dev', 'AUC', 'MI', 'AIC', 'GCV', 'BIC', 'UBRE'};

timePeriodNames = {'Intertrial Interval', 'Fixation', 'Rule Stimulus', 'Stimulus Response', 'Stimulus Reward', 'Rule Response', 'Saccade', 'Reward', 'Entire Trial'};
encode_period = {...
    {trialInfo('Start Trial Encode'), trialInfo('Fixation ON Encode')}; ... % Intertrial Interval
    {trialInfo('Fixation ACQUIRED Encode'), trialInfo('Rule ON Encode')}; ... % Fixation
    {trialInfo('Rule ON Encode'), trialInfo('Test Stimulus ON Encode')}; ... % Rule Stimulus
    {trialInfo('Test Stimulus ON Encode'), trialInfo('Saccade START Encode')}; ... % Stimulus Response
    {trialInfo('Test Stimulus ON Encode'), trialInfo('Reward START Encode')}; ... % Stimulus Reward
    {trialInfo('Rule ON Encode'), trialInfo('Saccade START Encode')}; ... % Rule Response
    {trialInfo('Saccade START Encode'), trialInfo('Reward START Encode')}; ... % Saccade
    {trialInfo('Reward START Encode'), trialInfo('End Trial Encode')}; ... % Reward
    {trialInfo('Start Trial Encode'), trialInfo('End Trial Encode')}; ... % Entire Trial
    };
encodeMap = containers.Map(timePeriodNames, encode_period);

numSpikeLags = 20;
numErrorLags = 5;
numRepetitionLags = 5;
% Set Acceptable Reaction Times
reactBounds = [100, 313]; % ms
%% Save Everything
save_file_name = sprintf('%s/paramSet.mat', main_dir);
save(save_file_name, '*Info', 'monkeyNames', 'validPredType', ...
    'timePeriodNames', 'encodeMap', 'num*', 'reactBounds');
