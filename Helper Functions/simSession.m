function [GLMCov, trial_time, isCorrect, isAttempted, trial_id] = simSession(numTrials)

setMainDir;
main_dir = getenv('MAIN_DIR');

% Load Common Parameters
load(sprintf('%s/paramSet.mat', main_dir), ...
    'data_info', 'cov_info');

GLMCov = cov_info;

numNeurons = 1;
pfc = true;
unit_number = 1;
wire_number = 1;
monkey_name = {'test'};

% Trial Time, ID
prepTime = round(100 + 200.*rand(numTrials, 1))';
trialTime = 160 + prepTime;

trial_id = convertFactor(1:numTrials, trialTime);

trial_time = cellfun(@(time) 1:time, num2cell(trialTime), 'UniformOutput', false);
trial_time = cat(2, trial_time{:})';

%% Preparation Time
GLMCov(ismember({cov_info.name}, 'Prep Time')).data = convertFactor(prepTime, trialTime);
GLMCov(ismember({cov_info.name}, 'Normalized Prep Time')).data = convertFactor(zscore(prepTime), trialTime);

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

GLMCov(ismember({cov_info.name}, 'Rule')).data = convertFactor(Rule, trialTime);

%% Switch History
difference = diff(Rule);
switc = zeros(1,numTrials);
switc(find(difference)+1) = 1;
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

GLMCov(ismember({cov_info.name}, 'Rule Repetition')).data = convertFactor(dist_sw, trialTime);

%% Congruency History
inCon = grp2idx(rand(1, numTrials) <= .7);
inCon = lagmatrix(inCon, 0:1)';

GLMCov(ismember({cov_info.name}, 'Congruency History')).data = [convertFactor(inCon(1, :), trialTime), convertFactor(inCon(2, :), trialTime)];

%% Response Direction
responseDir = grp2idx(rand(1, numTrials) <= .5)';

GLMCov(ismember({cov_info.name}, 'Response Direction')).data = convertFactor(responseDir, trialTime);

%% Error History
incorrect = rand(1, numTrials) <= .15;

errorHist = lagmatrix(grp2idx(incorrect), 1:5)';
Previous_Error_History = [];

for error_ind = 1:5,
    Previous_Error_History = [
        Previous_Error_History ...
        convertFactor(errorHist(error_ind, :), trialTime)...
        ];
end

GLMCov(ismember({cov_info.name}, 'Previous Error History')).data = Previous_Error_History;

% Distance from Error
dist_err = nan(size(incorrect));
err = find(incorrect);
num = diff(err);

for err_ind = 1:length(err)+1
    if err_ind == 1
        dist_err(1:err(err_ind)) = 0:err(err_ind)-1;
    elseif err_ind ~= length(err)+1
        dist_err(err(err_ind-1):(err(err_ind-1) + num(err_ind-1) - 1)) = 0:num(err_ind-1)-1;
    else
        dist_err(err(err_ind-1):end) = 0:(length(dist_err) - err(err_ind-1));
    end
end

dist_err(dist_err == 0) = NaN;
dist_err(dist_err >= 6) = 6;

% non-cumulative version of error history
GLMCov(ismember({cov_info.name}, 'Previous Error History Indicator')).data = convertFactor(dist_err, trialTime);

isCorrect = convertFactor(~incorrect, trialTime);
isAttempted = true(size(isCorrect));

% Indicator function for when the test stimulus is on
sample_on = trial_time >= GLMCov(ismember({cov_info.name}, 'Prep Time')).data;

% Compute the number of trials for each time point
table = tabulate(trial_time);
percent_trials = nan(size(trial_time));
for time_ind = 1:length(table(:,1))
    percent_trials(trial_time == table(time_ind,1)) = table(time_ind,3);
end

% 15. Trial Time
GLMCov(ismember({cov_info.name}, 'Trial Time')).data = trial_time;

%% Save Simulated Session
GLMCov_dir = sprintf('%s/Testing/GLMCov', data_info.processed_dir);
if ~exist(GLMCov_dir, 'dir'),
    mkdir(GLMCov_dir);
end

filename = sprintf('%s/test_GLMCov.mat', GLMCov_dir);
save(filename, 'GLMCov', 'monkey_name', 'percent_trials', ...
        'numNeurons', 'trial_id', 'trial_time', 'sample_on', ...
        'wire_number', 'unit_number', 'pfc', 'isCorrect', 'isAttempted', '-v7.3');

end

%%%%%%%%%%%%%%%%%%% Convert Factor %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [converted] = convertFactor(GLMCov, trialTime)

converted = cellfun(@(GLMCov, time) repmat(GLMCov, [1 time]), ...
    num2cell(GLMCov, 1), num2cell(trialTime), 'UniformOutput', false);

converted = cat(2, converted{:})';

end