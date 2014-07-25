function [factor, trial_id, trial_time, incorrect] = simSession(numTrials)
% Trial Time, ID
prepTime = round(100 + 200.*rand(numTrials, 1))';
trialTime = 160 + prepTime;

trial_id = convertFactor(1:numTrials, trialTime);

trial_time = cellfun(@(time) 1:time, num2cell(trialTime), 'UniformOutput', false);
trial_time = cat(2, trial_time{:})';

%% Preparation Time
factor.Prep_Time = convertFactor(prepTime, trialTime);
factor.Normalized_Prep_Time = convertFactor(zscore(prepTime), trialTime);

%% Rule Factor
Rule = nan(1, numTrials);
Rule(1) = true;
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
factor.Rule = convertFactor(Rule, trialTime);

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

factor.dist_sw = convertFactor(dist_sw, trialTime);

dist_sw(dist_sw >= 11) = 11;

factor.Switch_History = convertFactor(dist_sw, trialTime);

%% Congruency History
inCon = grp2idx(rand(1, numTrials) <= .7);
inCon = lagmatrix(inCon, 0:1)';

factor.Congruency_History = [convertFactor(inCon(1, :), trialTime), convertFactor(inCon(2, :), trialTime)];

%% Response Direction
responseDir = grp2idx(rand(1, numTrials) <= .5)';
factor.Response_Direction = convertFactor(responseDir, trialTime);

%% Error History
incorrect = rand(1, numTrials) <= .15;

errorHist = lagmatrix(grp2idx(incorrect), 1:10)';
factor.Previous_Error_History = [];

for error_ind = 1:10,
    factor.Previous_Error_History = [
        factor.Previous_Error_History ...
        convertFactor(errorHist(error_ind, :), trialTime)...
        ];
end

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
factor.dist_err = convertFactor(dist_err, trialTime);

dist_err(dist_err == 0) = NaN;
dist_err(dist_err >= 11) = 11;

% non-cumulative version of error history
factor.Previous_Error_History_Indicator = convertFactor(dist_err, trialTime);

incorrect = convertFactor(incorrect, trialTime);

end

function [converted] = convertFactor(factor, trialTime)

converted = cellfun(@(factor, time) repmat(factor, [1 time]), ...
    num2cell(factor, 1), num2cell(trialTime), 'UniformOutput', false);

converted = cat(2, converted{:})';

end