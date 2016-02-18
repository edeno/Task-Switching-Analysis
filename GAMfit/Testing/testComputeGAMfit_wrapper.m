function [saveDir, spikes] = testComputeGAMfit_wrapper(regressionModel_str, Rate, varargin)

mainDir = getWorkingDir();

load(sprintf('%s/paramSet.mat', mainDir), ...
    'validPredType', 'covInfo');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('Rate',  @(x) isnumeric(x) & all(x > 0));
inParser.addParameter('numFolds', 10, @(x) isnumeric(x) && x > 0)
inParser.addParameter('predType', 'Dev', @(x) any(ismember(x, validPredType)))
inParser.addParameter('smoothLambda', 0, @isvector)
inParser.addParameter('ridgeLambda', 0, @isvector)
inParser.addParameter('overwrite', false, @islogical)
inParser.addParameter('includeIncorrect', false, @islogical);
inParser.addParameter('includeFixationBreaks', false, @islogical);
inParser.addParameter('includeTimeBeforeZero', false, @islogical);
inParser.addParameter('isPrediction', false, @islogical);
inParser.addParameter('spikes', [], @(x) isnumeric(x));
inParser.addParameter('numCores', 2, @(x) isnumeric(x));

inParser.parse(regressionModel_str, Rate, varargin{:});

% Add parameters to input structure after validation
gamParams = inParser.Results;

gamParams.timePeriod = 'Testing';
gamParams.isLocal = true;

timePeriodDir = sprintf('%s/Processed Data/Testing/', mainDir);

% Simulate Spikes
if isempty(gamParams.spikes),
    dt = 1E-3;
    spikes = simPoisson(Rate, dt);
    % Append spikes to GLMCov file
    % Save Simulated Session
    SpikeCovName = sprintf('%s/SpikeCov/test_SpikeCov.mat', timePeriodDir);
    save(SpikeCovName, 'spikes', '-append');
else
    spikes = gamParams.spikes;
end

%% Estimate GAM parameters
profile -memory on;
saveDir = ComputeGAMfit('test', gamParams, covInfo);
profile viewer;

end