%% Define Covariates
covInfo = containers.Map;
%% Preparation Time
cov.levels = {'1 ms of prep time'};
cov.isCategorical = false;
cov.baselineLevel = [];
cov.isHistory = false;
covInfo('Preparation Time') = cov;
%% Indicator Preparation Time
cov.levels = {'Short' 'Medium', 'Long'};
cov.isCategorical = true;
cov.baselineLevel = 'Medium';
cov.isHistory = false;
covInfo('Preparation Time Indicator') = cov;
%% Normalized Preparation Time
cov.levels = {'1 Std Dev of Prep Time'};
cov.isCategorical = false;
cov.baselineLevel = [];
cov.isHistory = false;
covInfo('Normalized Preparation Time') = cov;
%% Rule
cov.levels = {'Orientation', 'Color'};
cov.isCategorical = true;
cov.baselineLevel = 'Color';
cov.isHistory = false;
covInfo('Rule') = cov;
%% Rule Cues
cov.levels = {'Color Cue1', 'Color Cue2', 'Orientation Cue1', 'Orientation Cue2'};
cov.isCategorical = true;
cov.baselineLevel = 'Color Cue1';
cov.isHistory = false;
covInfo('Rule Cues') = cov;
%% Rule Cue Switch
cov.levels = {'Repetition', 'Switch'};
cov.isCategorical = true;
cov.baselineLevel = 'Repetition';
cov.isHistory = false;
covInfo('Rule Cue Switch') = cov;
%% Test Stimulus
cov.levels = {'Vertical Blue', 'Vertical Red', 'Horizontal Blue', 'Horizontal Red'};
cov.isCategorical = true;
cov.baselineLevel = 'Vertical Blue';
cov.isHistory = false;
covInfo('Test Stimulus') = cov;
%% Response Direction
cov.levels = {'Right', 'Left'};
cov.isCategorical = true;
cov.baselineLevel = 'Right';
cov.isHistory = false;
covInfo('Response Direction') = cov;
%% Saccade
cov.levels = {'Right', 'Left'};
cov.isCategorical = true;
cov.baselineLevel = 'Right';
cov.isHistory = false;
covInfo('Saccade') = cov;
%% Previous Error
cov.levels = {'No Previous Error', 'Previous Error'};
cov.isCategorical = true;
cov.baselineLevel = 'No Previous Error';
cov.isHistory = false;
covInfo('Previous Error') = cov;
%% Previous Error History
errorHistNames = [strseq('No Previous Error', 1:numErrorLags) strseq('Previous Error', 1:numErrorLags)]';
cov.levels = errorHistNames(:)';
cov.isCategorical = true;
cov.baselineLevel = cov.levels(1:2:end);
cov.isHistory = true;
covInfo('Previous Error History') = cov;
%% Previous Error History Indicator
errorHistNames = ['Error'; strseq('Previous Error', 1:(numErrorLags-1)); sprintf('Previous Error%d+', numErrorLags)]';
cov.levels = errorHistNames;
cov.isCategorical = true;
cov.baselineLevel = sprintf('Previous Error%d+', numErrorLags);
cov.isHistory = false;
covInfo('Previous Error History Indicator') = cov;

%% Error Distance
cov.levels = {'1 Trial'};
cov.isCategorical = false;
cov.baselineLevel = [];
cov.isHistory = false;
covInfo('Error Distance') = cov;
%% Rule Repetition
ruleRepetitionNames = [strseq('Repetition', 1:numRepetitionLags); sprintf('Repetition%d+', numRepetitionLags)]';
cov.levels = ruleRepetitionNames;
cov.isCategorical = true;
cov.baselineLevel = sprintf('Repetition%d+', numRepetitionLags);
cov.isHistory = false;
covInfo('Rule Repetition') = cov;
%% Switch Distance
cov.levels = {'1 Trial'};
cov.isCategorical = false;
cov.baselineLevel = [];
cov.isHistory = false;
covInfo('Switch Distance') = cov;
%% Switch
cov.levels = {'Repetition', 'Switch'};
cov.isCategorical = true;
cov.baselineLevel = 'Repetition';
cov.isHistory = false;
covInfo('Switch') = cov;
%% Trial Time
cov.levels = {'1 ms'};
cov.isCategorical = false;
cov.baselineLevel = [];
cov.isHistory = false;
covInfo('Trial Time') = cov;
%% Congruency History
cov.levels = {'Congruent', 'Incongruent', 'Previous Congruent', 'Previous Incongruent'};
cov.isCategorical = true;
cov.baselineLevel = {'Congruent', 'Previous Congruent'};
cov.isHistory = true;
covInfo('Congruency History') = cov;
%% Previous Congruency
cov.levels = {'Previous Congruent', 'Previous Incongruent'};
cov.isCategorical = true;
cov.baselineLevel = 'Previous Congruent';
cov.isHistory = false;
covInfo('Previous Congruency') = cov;
%% Congurency
cov.levels = {'Congruent', 'Incongruent'};
cov.isCategorical = true;
cov.baselineLevel = 'Congruent';
cov.isHistory = false;
covInfo('Congruency') = cov;
%% Spike History
spikeNames = [strseq('No Previous Spike', 1:numSpikeLags) strseq('Previous Spike', 1:numSpikeLags)]';
cov.levels = spikeNames(:)';
cov.isCategorical = true;
cov.baselineLevel = cov.levels(1:2:end);
cov.isHistory = true;
covInfo('Spike History') = cov;
%% Session Time
cov.levels = {'Early', 'Middle', 'Late'};
cov.isCategorical = true;
cov.baselineLevel = 'Middle';
cov.isHistory = false;
covInfo('Session Time') = cov;
%% Append Information to ParamSet
save_file_name = sprintf('%s/paramSet.mat', main_dir);
save(save_file_name, 'covInfo', '-append');