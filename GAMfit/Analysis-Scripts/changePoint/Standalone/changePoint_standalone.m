function [timeToSig, timeToHalfMax, changeTimes, maxChangeTimes] = changePoint_standalone(neuron_ind, covOfInterest, model, timePeriod, varargin)
%#function getFirstHalfWidthmax
%#function getChangeTimes
%#function getFirstSigTime
%#function consecRuns

fprintf('\nMatlab\n')
fprintf('---------\n')
fprintf('neuron_ind: %s\n', neuron_ind);
fprintf('Model: %s\n', model);
fprintf('Time Period: %s\n', timePeriod);
fprintf('---------\n');

% Numbers are passed as strings. Need to convert to correct type
neuron_ind = str2double(neuron_ind);
if ~isempty(varargin),
    convert_ind = 2:2:length(varargin);
    varargin(convert_ind) = deal(cellfun(@(x) str2num(x), varargin(convert_ind), 'UniformOutput', false));
end
%% Validate Parameters
workingDir = getWorkingDir();

% Load Common Parameters
load(sprintf('%s/paramSet.mat', workingDir), ...
    'covInfo', 'timePeriodNames', 'neuronInfo');

inParser = inputParser;
inParser.addRequired('covOfInterest',  @(x) isKey(covInfo, x));
inParser.addRequired('model', @ischar);
inParser.addRequired('timePeriod',  @(x) any(ismember(x, timePeriodNames)));
inParser.addParameter('overwrite', true, @isnumeric)

inParser.parse(covOfInterest, model, timePeriod, varargin{:});

% Add parameters to input structure after validation
params = inParser.Results;
myCluster = parcluster('local');
if getenv('ENVIRONMENT')    % true if this is a batch job
    myCluster.JobStorageLocation = getenv('TMPDIR');  % points to TMPDIR
end

neuronNames = [neuronInfo.values];
neuronNames = [neuronNames{:}];
neuronNames = {neuronNames.name};
neuronNames = cellfun(@(x) strrep(x, '-', '_'), neuronNames, 'UniformOutput', false);
neuronName = neuronNames{neuron_ind};

modelDir = sprintf('%s/Processed Data/%s/Models/', workingDir, timePeriod);
load(sprintf('%s/modelList.mat', modelDir), 'modelList');
saveDir = sprintf('%s/%s/changePoint/%s', modelDir, modelList(model), covOfInterest);
if ~exist(saveDir, 'dir'),
    mkdir(saveDir);
end
saveFileName = sprintf('%s/%s_changePoint.mat', saveDir, neuronName);
if exist(saveFileName, 'file') && ~params.overwrite,
    fprintf('File %s already exists. Skipping.\n', saveFileName);
    return;
end

timeToSig = getFirstSigTime(neuronName, covOfInterest, timePeriod, model);
timeToHalfMax = getFirstHalfWidthMax(neuronName, covOfInterest, timePeriod, model);
[changeTimes, maxChangeTimes] = getChangeTimes(neuronName, covOfInterest, timePeriod, model);

fprintf('\nSaving...\n');
save(saveFileName, 'timeToSig', 'timeToHalfMax', 'changeTimes', 'maxChangeTimes', 'params', 'neuronName', '-v7.3');

end