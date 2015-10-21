% Constructs SpikeCovariates for use with GLMfit
function [SpikeCov, spikes, ...
    numNeurons, trial_id, trial_time, percent_trials, ...
    wire_number, unit_number, pfc, isCorrect, isAttempted] = ExtractSpikeCovariatesBySession(sessionName, timePeriod, numLags, covInfo, behavior, varargin)

%% Load Common Parameters and Parse Inputs
main_dir = getWorkingDir();

inParser = inputParser;
inParser.addParameter('overwrite', false, @islogical);

inParser.parse(varargin{:});

SpikeCovParams = inParser.Results;

%% Check if File Exists Already
save_file_name = sprintf('%s/Processed Data/%s/SpikeCov/%s_SpikeCov.mat', main_dir, timePeriod, sessionName);
if (exist(save_file_name, 'file') && ~SpikeCovParams.overwrite),
    fprintf('File %s already exists. Skipping.\n', save_file_name);
    return;
end
%% Load Data and Behavior File
dataSessionFile = sprintf('%s/Processed Data/%s/%s_data.mat', main_dir, timePeriod, sessionName);
fprintf('\nProcessing file %s...\n', sessionName);
load(dataSessionFile);
%% Setup Covariates
time = time(:)';
data = data(:)';
%% Do some organizing
spikes = cat(1, data{:});
trial_time = cat(2, time{:})';

numNeurons = size(spikes, 2);
%% What trial does each time correspond to?
trial_id = num2cell(1:size(time, 2));

trial_id = cellfun(@(x,y) x(ones(size(y))), trial_id, time, 'UniformOutput', false);
trial_id = cat(2, trial_id{:})';
%% Label each trial time point with the appropriate covariate
covNames = covInfo.keys;

SpikeCov = containers.Map;

for cov_ind = 1:covInfo.count,
    switch(covNames{cov_ind})
        case 'Spike History'
            %% Compute the spiking history
            % The function lag matrix takes up too much memory if given a large amount
            % of memory so break up the data into smaller bits
            spike_hist = spalloc(size(spikes, 1), numNeurons * numLags, nansum(nansum(spikes)) * numLags);
            
            parts_quant = unique(floor(quantile(1:(numLags+1), [0:0.1:1])));
            
            for parts_ind = 1:(length(parts_quant)-1),
                curLags = parts_quant(parts_ind):(parts_quant(parts_ind+1)-1);
                part_hist = lagmatrix(spikes, curLags);
                part_hist(isnan(part_hist)) = 0;
                spike_hist(:, [1:(numNeurons * length(curLags))] + (parts_quant(parts_ind) - 1) * numNeurons) = sparse(part_hist);
            end
            cov.data = spike_hist;
            SpikeCov(covNames{cov_ind}).data = cov;
        case 'Trial Time'
            cov.data = trial_time;
            SpikeCov(covNames{cov_ind}).data = cov;
        otherwise
            cov.data = behavior(covNames{cov_ind}).data(trial_id, :);
            SpikeCov(covNames{cov_ind}).data = cov;
    end
end

isAttempted = behavior('Attempted').data(trial_id);
isCorrect = behavior('Correct').data(trial_id);

% Compute the number of trials for each time point
table = tabulate(trial_time);
percent_trials = nan(size(trial_time));
for time_ind = 1:length(table(:,1))
    percent_trials(trial_time == table(time_ind, 1)) = table(time_ind, 3);
end
%% Find which areas correspond to PFC
% isa5 is a special case
if strcmp(sessionName, 'isa5'),
    pfc = wire_number <= 16;
else
    pfc = wire_number <= 8;
end

%% Save Everything
fprintf('\nSaving to %s....\n', save_file_name);
save_dir = sprintf('%s/Processed Data/%s/SpikeCov', main_dir, timePeriod);
if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end

save(save_file_name, 'SpikeCov', 'spikes', ...
    'numNeurons', 'trial_id', 'trial_time', 'percent_trials', ...
    'wire_number', 'unit_number', 'pfc', 'isCorrect', 'isAttempted', '-v7.3');

end