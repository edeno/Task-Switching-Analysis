function [GLMCov, trial_id, trial_time, incorrect] = simSession(numTrials)
% Trial Time, ID
prepTime = round(100 + 200.*rand(numTrials, 1))';
trialTime = 160 + prepTime;

trial_id = convertFactor(1:numTrials, trialTime);

trial_time = cellfun(@(time) 1:time, num2cell(trialTime), 'UniformOutput', false);
trial_time = cat(2, trial_time{:})';

%% Preparation Time
GLMCov(1).name = 'Prep Time';
GLMCov(1).levels = {'1 ms of prep time'};
GLMCov(1).isCategorical = false;
GLMCov(1).data = convertFactor(prepTime, trialTime);

GLMCov(2).name = 'Normalized Prep Time';
GLMCov(2).levels = {'1 Std Dev of Prep Time'};
GLMCov(2).isCategorical = false;
GLMCov(2).data = convertFactor(zscore(prepTime), trialTime);

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

GLMCov(3).name = 'Rule';
GLMCov(3).levels = {'Orientation', 'Color'};
GLMCov(3).isCategorical = true;
GLMCov(3).data = convertFactor(Rule, trialTime);

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

dist_sw(dist_sw >= 11) = 11;

GLMCov(4).name = 'Switch History';
switch_hist_names = [strseq('Repetition', 1:10); 'Repetition11+']';
GLMCov(4).levels = switch_hist_names;
GLMCov(4).isCategorical = true;
GLMCov(4).data = convertFactor(dist_sw, trialTime);

%% Congruency History
inCon = grp2idx(rand(1, numTrials) <= .7);
inCon = lagmatrix(inCon, 0:1)';

GLMCov(5).name = 'Congruency History';
GLMCov(5).levels = {'Congruent', 'Incongruent', 'Previous Congruent', 'Previous Incongruent'};
GLMCov(5).isCategorical = true;
GLMCov(5).data = [convertFactor(inCon(1, :), trialTime), convertFactor(inCon(2, :), trialTime)];

%% Response Direction
responseDir = grp2idx(rand(1, numTrials) <= .5)';

GLMCov(6).name = 'Response Direction';
GLMCov(6).levels = {'Right', 'Left'};
GLMCov(6).isCategorical = true;
GLMCov(6).data = convertFactor(responseDir, trialTime);

%% Error History
incorrect = rand(1, numTrials) <= .15;

errorHist = lagmatrix(grp2idx(incorrect), 1:10)';
Previous_Error_History = [];

for error_ind = 1:10,
    Previous_Error_History = [
        Previous_Error_History ...
        convertFactor(errorHist(error_ind, :), trialTime)...
        ];
end

GLMCov(7).name = 'Previous Error History';
error_hist_names = [strseq('No Previous Error', 1:10) strseq('Previous Error', 1:10)]';
GLMCov(7).levels = error_hist_names(:)';
GLMCov(7).isCategorical = true;
GLMCov(7).data = Previous_Error_History;

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
dist_err(dist_err >= 11) = 11;

% non-cumulative version of error history
GLMCov(8).name = 'Previous Error History Indicator';
error_hist_names = [strseq('Previous Error', 1:10); 'Previous Error11+']';
GLMCov(8).levels = error_hist_names;
GLMCov(8).isCategorical = true;
GLMCov(8).data = convertFactor(dist_err, trialTime);

incorrect = convertFactor(incorrect, trialTime);

end

function [converted] = convertFactor(GLMCov, trialTime)

converted = cellfun(@(GLMCov, time) repmat(GLMCov, [1 time]), ...
    num2cell(GLMCov, 1), num2cell(trialTime), 'UniformOutput', false);

converted = cat(2, converted{:})';

end