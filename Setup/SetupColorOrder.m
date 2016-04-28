%% Covariate levels -> color
clear variables;
workingDir = getWorkingDir();
load(sprintf('%s/paramSet.mat', workingDir), 'covInfo');
colorInfo = containers.Map;

sequentialColorOrder = [ ...
    37,52,148; ...
    44,127,184; ...
    65,182,196; ...
    127,205,187; ...
    199,233,180; ...
    ] ./ 255;

baselineColor = [189,189,189] ./ 255;
% Rule
colorInfo('Orientation') = [141,160,203] ./ 255;
colorInfo('Color') = [231,138,195] ./ 255;

% Rule Cues
colorInfo('Orientation Cue1') = [141,160,203] ./ 255;
colorInfo('Color Cue1') = [231,138,195] ./ 255;
colorInfo('Orientation Cue2') = [203,213,232] ./ 255;
colorInfo('Color Cue2') = [244,202,228] ./ 255;

% Response Direction
colorInfo('Left') = [252,141,98] ./ 255;
colorInfo('Right') = [102,194,165] ./ 255;

% Rule Repetition
for k = 1:length(covInfo('Rule Repetition').levels),
    colorInfo(covInfo('Rule Repetition').levels{k}) = sequentialColorOrder(k, :);
end

% Congruecy
colorInfo('Congruent') = baselineColor;
colorInfo('Incongruent') = sequentialColorOrder(1, :);

% Previous Error History
for k = 1:2:length(covInfo('Previous Error History').levels),
    colorInfo(covInfo('Previous Error History').levels{k}) =  baselineColor;
end

for k = 2:2:length(covInfo('Previous Error History').levels),
    colorInfo(covInfo('Previous Error History').levels{k}) =  sequentialColorOrder(k / 2, :);
end

% Previous Error
colorInfo('No Previous Error') = baselineColor;
colorInfo('Previous Error') = sequentialColorOrder(1, :);

save(sprintf('%s/paramSet.mat', workingDir), 'colorInfo', '-append');
