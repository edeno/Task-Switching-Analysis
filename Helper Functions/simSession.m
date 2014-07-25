function [factor] = simSession(numTrials)

colorRule = nan(1, numTrials);
colorRule(1) = true;
trialBlock_counter = 0;

for trial_ind = 1:numTrials,
    if trialBlock_counter > 20,
        if rand <= .05,
            colorRule(trial_ind) =  ~colorRule(trial_ind -1);
            trialBlock_counter = 0;
        else
            colorRule(trial_ind) =  colorRule(trial_ind -1);
        end
    else
        if trial_ind ~= 1,
            colorRule(trial_ind) =  colorRule(trial_ind -1);
        end
        trialBlock_counter = trialBlock_counter + 1;
    end
end

switchTrial = find(diff(colorRule))+1;
sw = zeros(1, numTrials);
sw(switchTrial) = 1;
switchHistory = lagmatrix(sw, 0:5);
switchHistory(isnan(switchHistory)) = 0;
switchHistory = [switchHistory ~logical(sum(switchHistory, 2))]';

inCon = rand(1, numTrials) <= .7;

responseDir = rand(1, numTrials) <= .5;

prepTime = round(100 + 200.*rand(numTrials, 1))';
trialTime = 160 + prepTime;

convertFactor = @(factor) cellfun(@(factor, time) repmat(factor, [1 time]), ...
    num2cell(factor, 1), num2cell(trialTime), 'UniformOutput', false);

trial_id = convertFactor(1:numTrials);
factor.trial_id = cat(2, trial_id{:})';

time = cellfun(@(time) 1:time, num2cell(trialTime), 'UniformOutput', false);
factor.time = cat(2, time{:})';

colorRule = convertFactor(colorRule);
factor.colorRule = cat(2, colorRule{:})';

responseDir = convertFactor(responseDir);
factor.responseDir = cat(2, responseDir{:})';

inCon = convertFactor(inCon);
factor.inCon = cat(2, inCon{:})';

switchHistory = convertFactor(switchHistory);
factor.switchHistory = cat(2, switchHistory{:})';

prepTime = convertFactor(prepTime);
factor.prepTime = cat(2, prepTime{:})';
end