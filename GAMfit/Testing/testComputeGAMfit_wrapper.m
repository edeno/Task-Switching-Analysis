function [neurons, stats, gam, designMatrix, spikes, save_dir, gamParams] = testComputeGAMfit_wrapper(regressionModel_str, Rate, varargin)

setMainDir;
main_dir = getenv('MAIN_DIR');

load(sprintf('%s/paramSet.mat', main_dir), ...
    'data_info', 'validPredType');

inParser = inputParser;
inParser.addRequired('regressionModel_str', @ischar);
inParser.addRequired('Rate',  @(x) isnumeric(x) & all(x > 0));
inParser.addParamValue('numFolds', 10, @(x) isnumeric(x) && x > 0)
inParser.addParamValue('predType', 'Dev', @(x) any(ismember(x, validPredType)))
inParser.addParamValue('smoothLambda', 0, @isvector)
inParser.addParamValue('ridgeLambda', 0, @isvector)
inParser.addParamValue('overwrite', false, @islogical)
inParser.addParamValue('includeIncorrect', false, @islogical);
inParser.addParamValue('includeFixationBreaks', false, @islogical);
inParser.addParamValue('includeTimeBeforeZero', false, @islogical);
inParser.addParamValue('isPrediction', false, @islogical);
inParser.addParamValue('spikes', [], @(x) isnumeric(x));

inParser.parse(regressionModel_str, Rate, varargin{:});

% Add parameters to input structure after validation
gamParams = inParser.Results;

timePeriod_dir = sprintf('%s/Testing/', data_info.processed_dir);

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



% Save directory
save_dir = sprintf('%s/Models/%s', timePeriod_dir, gamParams.regressionModel_str);
if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end

% Estimate GAM parameters
[neurons, stats, gam, designMatrix] = ComputeGAMfit(timePeriod_dir, 'test', gamParams, save_dir);

end