function [saveDir, p, obsDiff, randDiff] = testbasicPopulationAnalysis_wrapper(covariateOfInterest, Rate, varargin)

mainDir = getWorkingDir();

load(sprintf('%s/paramSet.mat', mainDir), ...
    'validPredType', 'covInfo');

inParser = inputParser;
inParser.addRequired('covariateOfInterest', @ischar);
inParser.addRequired('Rate',  @(x) isnumeric(x) & all(x > 0));
inParser.addParameter('overwrite', true, @islogical)
inParser.addParameter('includeIncorrect', false, @islogical);
inParser.addParameter('includeFixationBreaks', false, @islogical);
inParser.addParameter('includeTimeBeforeZero', false, @islogical);
inParser.addParameter('spikes', [], @(x) isnumeric(x));
inParser.addParameter('numRand', 1000, @(x) isnumeric(x));
inParser.addParameter('numCores', 8, @(x) isnumeric(x));

inParser.parse(covariateOfInterest, Rate, varargin{:});

% Add parameters to input structure after validation
popParams = inParser.Results;

popParams.timePeriod = 'Testing';
popParams.isLocal = true;

timePeriodDir = sprintf('%s/Processed Data/Testing/', mainDir);

% Simulate Spikes
if isempty(popParams.spikes),
    dt = 1E-3;
    spikes = simPoisson(Rate, dt);
    % Append spikes to GLMCov file
    % Save Simulated Session
    SpikeCovName = sprintf('%s/SpikeCov/test_SpikeCov.mat', timePeriodDir);
    save(SpikeCovName, 'spikes', '-append');
else
    spikes = popParams.spikes;
end

%% Estimate GAM parameters
profile -memory on;
[saveDir, p, obsDiff, randDiff] = BasicPopulationAnalysis('test', popParams, covInfo);
profile viewer;

end