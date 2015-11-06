% Constructs SpikeCovariates for use with GLMfit
function [spikeCov, spikes, ...
    numNeurons, trialID, trialTime, percentTrials, ...
    wire_number, unit_number, neuronBrainArea, isCorrect, isAttempted] = ExtractSpikeCovariatesBySession(sessionName, timePeriod, numSpikeLags, covInfo, behavior, varargin)
%% Load Common Parameters and Parse Inputs
mainDir = getWorkingDir();

inParser = inputParser;
inParser.addParamValue('overwrite', false, @islogical); %#ok<NVREPL>
inParser.parse(varargin{:});

SpikeCovParams = inParser.Results;
%% Check if File Exists Already
saveFileName = sprintf('%s/Processed Data/%s/SpikeCov/%s_SpikeCov.mat', mainDir, timePeriod, sessionName);
if (exist(saveFileName, 'file') && ~SpikeCovParams.overwrite),
    fprintf('File %s already exists. Skipping.\n', saveFileName);
    return;
end
%% Load Data and Behavior File
dataSessionFile = sprintf('%s/Processed Data/%s/%s_data.mat', mainDir, timePeriod, sessionName);
fprintf('\nProcessing file %s...\n', sessionName);
load(dataSessionFile);
%% Setup Covariates
time = time(:)';
data = data(:)';
%% Do some organizing
spikes = cat(1, data{:});
trialTime = cat(2, time{:})';
numNeurons = size(spikes, 2);
%% What trial does each time correspond to?
trialID = num2cell(1:size(time, 2));

trialID = cellfun(@(x,y) x(ones(size(y))), trialID, time, 'UniformOutput', false);
trialID = cat(2, trialID{:})';
%% Label each trial time point with the appropriate covariate
covNames = covInfo.keys;
spikeCov = containers.Map;
for cov_ind = 1:covInfo.Count,
    switch(covNames{cov_ind})
        case 'Spike History'
            % Compute the spiking history
            % The function lag matrix takes up too much memory if given a large amount
            % of memory so break up the data into smaller bits
            spike_hist = spalloc(size(spikes, 1), numNeurons * numSpikeLags, nansum(nansum(spikes)) * numSpikeLags);
            
            parts_quant = unique(floor(quantile(1:(numSpikeLags+1), [0:0.1:1])));
            
            for parts_ind = 1:(length(parts_quant)-1),
                curLags = parts_quant(parts_ind):(parts_quant(parts_ind+1)-1);
                part_hist = lagmatrix(spikes, curLags);
                part_hist(isnan(part_hist)) = 0;
                spike_hist(:, [1:(numNeurons * length(curLags))] + (parts_quant(parts_ind) - 1) * numNeurons) = sparse(part_hist);
            end
            spikeCov(covNames{cov_ind}) = spike_hist;
        case 'Trial Time'
            spikeCov(covNames{cov_ind}) = trialTime;
        otherwise
            cov = behavior(covNames{cov_ind});
            cov = cov(trialID, :);
            spikeCov(covNames{cov_ind}) = cov;
    end
end

isAttempted = behavior('Attempted');
isAttempted = isAttempted(trialID);
isCorrect = behavior('Correct');
isCorrect = isCorrect(trialID);

% Compute the number of trials for each time point
[n, bin] = histc(trialTime, [min(trialTime):max(trialTime) + 1]);
percentTrials = n(bin) / max(n);
%% Find which areas correspond to PFC
% isa5 is a special case
neuronBrainArea = cell(size(wire_number));
if strcmp(sessionName, 'isa5'),
    neuronBrainArea(wire_number <= 16) = {'dlPFC'};
    neuronBrainArea(wire_number > 16) = {'ACC'};
else
    neuronBrainArea(wire_number <= 8) = {'dlPFC'};
    neuronBrainArea(wire_number > 8) = {'ACC'};
end

%% Save Everything
fprintf('\nSaving to %s....\n', saveFileName);
save_dir = sprintf('%s/Processed Data/%s/SpikeCov', mainDir, timePeriod);
if ~exist(save_dir, 'dir'),
    mkdir(save_dir);
end

save(saveFileName, 'spikeCov', 'spikes', ...
    'numNeurons', 'trialID', 'trialTime', 'percentTrials', ...
    'wire_number', 'unit_number', 'neuronBrainArea', 'isCorrect', 'isAttempted', '-v7.3');

end