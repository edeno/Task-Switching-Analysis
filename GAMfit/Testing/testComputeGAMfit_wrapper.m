function [neurons, stats, gam, designMatrix, spikes, gamParams] = testComputeGAMfit_wrapper(regressionModel_str, Rate, varargin)

main_dir = getWorkingDir();

load(sprintf('%s/paramSet.mat', main_dir), ...
    'data_info', 'validPredType');

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

inParser.parse(regressionModel_str, Rate, varargin{:});

% Add parameters to input structure after validation
gamParams = inParser.Results;

gamParams.timePeriod = 'Testing';
gamParams.isLocal = true;

timePeriod_dir = sprintf('%s/Processed Data/Testing/', main_dir);

% Simulate Spikes
if isempty(gamParams.spikes),
    dt = 1E-3;
    spikes = simPoisson(Rate, dt);
    % Append spikes to GLMCov file
    % Save Simulated Session
    GLMCov_name = sprintf('%s/GLMCov/test_GLMCov.mat', timePeriod_dir);
    save(GLMCov_name, 'spikes', '-append');
else
    spikes = gamParams.spikes;
end

%% Estimate GAM parameters
[neurons, stats, gam, designMatrix] = ComputeGAMfit('test', gamParams);

end