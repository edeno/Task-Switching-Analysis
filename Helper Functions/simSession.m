function [spikeCov, trialTime, isCorrect, isAttempted, trialID, percentTrials] = simSession(numTrials)

mainDir = getWorkingDir();

% Load Common Parameters
load(sprintf('%s/paramSet.mat', mainDir), 'numErrorLags');

spikeCov = containers.Map;

numNeurons = 1;
neuronBrainArea = {'Test'};
unit_number = 1;
wire_number = 1;
monkeyName = {'test'};

% Trial Time, ID
prepTime = round(100 + 200.*rand(numTrials, 1))';
trialTimeByTrial = 160 + prepTime;

trialID = convertFactor(1:numTrials, trialTimeByTrial);

trialTime = cellfun(@(time) 1:time, num2cell(trialTimeByTrial), 'UniformOutput', false);
trialTime = cat(2, trialTime{:})';
%% Preparation Time
spikeCov('Preparation Time') = convertFactor(prepTime, trialTimeByTrial);
spikeCov('Normalized Preparation Time') = convertFactor(zscore(prepTime), trialTimeByTrial);
%% Rule Factor
Rule = nan(1, numTrials);
Rule(1) = rand < 0.5;
trialBlock_counter = 0;

for trial_ind = 1:numTrials,
    if trialBlock_counter > 20,
        if rand <= .05,
            Rule(trial_ind) =  ~Rule(trial_ind -1);
            trialBlock_counter = 0;
        else
            Rule(trial_ind) =  Rule(trial_ind -1);
        end
    else
        if trial_ind ~= 1,
            Rule(trial_ind) =  Rule(trial_ind -1);
        end
        trialBlock_counter = trialBlock_counter + 1;
    end
end

Rule = grp2idx(Rule)';
spikeCov('Rule') = convertFactor(Rule, trialTimeByTrial);
%% Switch History
difference = diff(Rule);
switc = zeros(1, numTrials);
switc(find(difference) + 1) = 1;
switc = grp2idx(switc);

dist_sw = nan(size(switc));
sw = find(switc == 2);
num = diff(sw);

for sw_ind = 1:length(sw)+1
    if sw_ind == 1
        dist_sw(1:sw(sw_ind)) = 0:sw(sw_ind)-1;
    elseif sw_ind ~= length(sw)+1
        dist_sw(sw(sw_ind-1):(sw(sw_ind-1) + num(sw_ind-1) - 1)) = 0:num(sw_ind-1)-1;
    else
        dist_sw(sw(sw_ind-1):end) = 0:(length(dist_sw) - sw(sw_ind-1));
    end
end
dist_sw = dist_sw'+1;

dist_sw(dist_sw >= 6) = 6;

spikeCov('Rule Repetition') = convertFactor(dist_sw, trialTimeByTrial);
%% Congruency History
inCon = grp2idx(rand(1, numTrials) <= .7);
inCon = lagmatrix(inCon, 0:1)';
spikeCov('Congruency History') = [convertFactor(inCon(1, :), trialTimeByTrial), ...
    convertFactor(inCon(2, :), trialTimeByTrial)];
%% Response Direction
responseDir = grp2idx(rand(1, numTrials) <= .5)';
spikeCov('Response Direction') = convertFactor(responseDir, trialTimeByTrial);
%% Error History
incorrect = rand(1, numTrials) <= .15;

errorHist = lagmatrix(grp2idx(incorrect), 1:numErrorLags)';
Previous_Error_History = [];

for error_ind = 1:numErrorLags,
    Previous_Error_History = [
        Previous_Error_History ...
        convertFactor(errorHist(error_ind, :), trialTimeByTrial)...
        ];
end

spikeCov('Previous Error History') =  Previous_Error_History;

% Distance from Error
distErr = nan(size(incorrect));
err = find(incorrect);
num = diff(err);

for err_ind = 1:length(err)+1
    if err_ind == 1
        distErr(1:err(err_ind)) = 0:err(err_ind)-1;
    elseif err_ind ~= length(err)+1
        distErr(err(err_ind-1):(err(err_ind-1) + num(err_ind-1) - 1)) = 0:num(err_ind-1)-1;
    else
        distErr(err(err_ind-1):end) = 0:(length(distErr) - err(err_ind-1));
    end
end

distErr(distErr == 0) = NaN;
distErr(distErr >= numErrorLags) = numErrorLags;

% non-cumulative version of error history
spikeCov('Previous Error History Indicator') = convertFactor(distErr, trialTimeByTrial);

isCorrect = convertFactor(~incorrect, trialTimeByTrial);
isAttempted = true(size(isCorrect));

% Compute the number of trials for each time point
% Compute the number of trials for each time point
[n, bin] = histc(trialTime, [min(trialTime):max(trialTime) + 1]);
percentTrials = n(bin) / max(n);

% Trial Time
spikeCov('Trial Time') = trialTime;
%% Save Simulated Session
spikeCovDir = sprintf('%s/Processed Data/Testing/SpikeCov', mainDir);
if ~exist(spikeCovDir, 'dir'),
    mkdir(spikeCovDir);
end

filename = sprintf('%s/test_spikeCov.mat', spikeCovDir);
save(filename, 'spikeCov', 'monkeyName', 'percentTrials', ...
        'numNeurons', 'trialID', 'trialTime', ...
        'wire_number', 'unit_number', 'neuronBrainArea', 'isCorrect', 'isAttempted', '-v7.3');

end

%%%%%%%%%%%%%%%%%%% Convert Factor %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [converted] = convertFactor(covariateDataByTrial, trialTimeByTrial)

converted = cellfun(@(cov, time) repmat(cov, [1 time]), ...
    num2cell(covariateDataByTrial, 1), num2cell(trialTimeByTrial), 'UniformOutput', false);

converted = cat(2, converted{:})';
end