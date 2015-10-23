%% Define Covariates
covInfo = containers.Map;
%% Preparation Time
cov.levels = {'1 ms of prep time'};
cov.isCategorical = false;
cov.baselineLevel = [];
covInfo('Preparation Time') = cov;
clear cov;
%% Indicator Preparation Time
cov.levels = {'Short' 'Medium', 'Long'};
cov.isCategorical = true;
cov.baselineLevel = 'Medium';
covInfo('Preparation Time Indicator') = cov;
clear cov;
%% Normalized Preparation Time
cov.levels = {'1 Std Dev of Prep Time'};
cov.isCategorical = false;
cov.baselineLevel = [];
covInfo('Normalized Preparation Time') = cov;
clear cov;
%% Rule
cov.levels = {'Orientation', 'Color'};
cov.isCategorical = true;
cov.baselineLevel = 'Color';
covInfo('Rule') = cov;
clear cov;
%% Rule Cues
cov.levels = {'Color Cue1', 'Color Cue2', 'Orientation Cue1', 'Orientation Cue2'};
cov.isCategorical = true;
cov.baselineLevel = 'Color Cue1';
covInfo('Rule Cues') = cov;
clear cov;
%% Rule Cue Switch
cov.levels = {'Repetition', 'Switch'};
cov.isCategorical = true;
cov.baselineLevel = 'Repetition';
covInfo('Rule Cue Switch') = cov;
clear cov;
%% Test Stimulus
cov.levels = {'Vertical Blue', 'Vertical Red', 'Horizontal Blue', 'Horizontal Red'};
cov.isCategorical = true;
cov.baselineLevel = 'Vertical Blue';
covInfo('Test Stimulus') = cov;
clear cov;
%% Response Direction
cov.levels = {'Right', 'Left'};
cov.isCategorical = true;
cov.baselineLevel = 'Right';
covInfo('Response Direction') = cov;
clear cov;
%% Saccade
cov.levels = {'Right', 'Left'};
cov.isCategorical = true;
cov.baselineLevel = 'Right';
covInfo('Saccade') = cov;
clear cov;
%% Previous Error
cov.levels = {'No Previous Error', 'Previous Error'};
cov.isCategorical = true;
cov.baselineLevel = 'No Previous Error';
covInfo('Previous Error') = cov;
clear cov;
%% Previous Error History
errorHistNames = [strseq('No Previous Error', 1:numErrorLags) strseq('Previous Error', 1:numErrorLags)]';
cov.levels = errorHistNames(:)';
cov.isCategorical = true;
cov.baselineLevel = cov.levels(1:2:end);
covInfo('Previous Error History') = cov;
clear cov;
%% Previous Error History Indicator
errorHistNames = ['Error'; strseq('Previous Error', 1:(numErrorLags-1)); sprintf('Previous Error%d+', numErrorLags)]';
cov.levels = errorHistNames;
cov.isCategorical = true;
cov.baselineLevel = sprintf('Previous Error%d+', numErrorLags);
covInfo('Previous Error History Indicator') = cov;
clear cov;
%% Error Distance
cov.levels = {'1 Trial'};
cov.isCategorical = false;
cov.baselineLevel = [];
covInfo('Error Distance') = cov;
clear cov;
%% Rule Repetition
ruleRepetitionNames = [strseq('Repetition', 1:numRepetitionLags); sprintf('Repetition%d+', numRepetitionLags)]';
cov.levels = ruleRepetitionNames;
cov.isCategorical = true;
cov.baselineLevel = sprintf('Repetition%d+', numRepetitionLags);
covInfo('Rule Repetition') = cov;
clear cov;
%% Switch Distance
cov.levels = {'1 Trial'};
cov.isCategorical = false;
cov.baselineLevel = [];
covInfo('Switch Distance') = cov;
clear cov;
%% Switch
cov.levels = {'Repetition', 'Switch'};
cov.isCategorical = true;
cov.baselineLevel = 'Repetition';
covInfo('Switch') = cov;
clear cov;
%% Trial Time
cov.levels = {'1 ms'};
cov.isCategorical = false;
cov.baselineLevel = [];
covInfo('Trial Time') = cov;
clear cov;
%% Congruency History
cov.levels = {'Congruent', 'Incongruent', 'Previous Congruent', 'Previous Incongruent'};
cov.isCategorical = true;
cov.baselineLevel = {'Congruent', 'Previous Congruent'};
covInfo('Congruency History') = cov;
clear cov;
%% Previous Congruency
cov.levels = {'Previous Congruent', 'Previous Incongruent'};
cov.isCategorical = true;
cov.baselineLevel = 'Previous Congruent';
covInfo('Previous Congruency') = cov;
clear cov;
%% Congurency
cov.levels = {'Congruent', 'Incongruent'};
cov.isCategorical = true;
cov.baselineLevel = 'Congruent';
covInfo('Congruency') = cov;
clear cov;
%% Spike History
spikeNames = [strseq('No Previous Spike', 1:numSpikeLags) strseq('Previous Spike', 1:numSpikeLags)]';
cov.levels = spikeNames(:)';
cov.isCategorical = true;
cov.baselineLevel = cov.levels(1:2:end);
covInfo('Spike History') = cov;
clear cov;
%% Session Time
cov.levels = {'Early', 'Middle', 'Late'};
cov.isCategorical = true;
cov.baselineLevel = 'Middle';
covInfo('Session Time') = cov;
clear cov;
%%
validCov = {covInfo.keys};
%% Append Information to ParamSet
save_file_name = sprintf('%s/paramSet.mat', main_dir);
save(save_file_name, 'covInfo', '-append');