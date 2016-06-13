models = {'Rule + Previous Error History + Rule Repetition', 'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction'};
timePeriod = {'Rule Stimulus', 'Stimulus Response'};

parEst = cell(length(models), 1);
gam = cell(length(models), 1);

for model_ind = 1:length(models),
    [parEst{model_ind}, gam{model_ind}, neuronNames, neuronBrainAreas] = getCoef(models{model_ind}, timePeriod{model_ind});    
end

parEst = cat(2, parEst{:});
gam = [gam{:}];
levelNames = cat(2, gam.levelNames);
ruleStim_ind = 1:length(gam(1).levelNames);
stimResponse_ind = (length(gam(1).levelNames) + 1):(length(gam(2).levelNames) + length(gam(1).levelNames));
intercept_ind = ismember(levelNames, '(Intercept)');
levelNames(ruleStim_ind) = strcat(timePeriod{1}, ':', levelNames(ruleStim_ind));
levelNames(stimResponse_ind) = strcat(timePeriod{2}, ':', levelNames(stimResponse_ind));

bad_ind = any(abs(parEst(:, 2:end)) > 10, 2);

%% PCA
curBrainAreas = neuronBrainAreas(~bad_ind);
[coeffs, score, latent, tSquared, explained, mu] = pca(parEst(~bad_ind, ~intercept_ind), 'centered', false);
figure;
plotHandle = biplot(coeffs(:,1:2), 'scores', score(:,1:2), ...
    'varlabels', levelNames(~intercept_ind), ...
    'ObsLabels', cellfun(@(x,y) sprintf('%s %s', x, y), neuronBrainAreas(~bad_ind), neuronNames(~bad_ind), 'UniformOutput', false), ...
    'MarkerSize', 10);
for k = 1:length(plotHandle),
    if strcmp(plotHandle(k).Tag, 'obsmarker'),
        if strcmp(curBrainAreas(plotHandle(k).UserData), 'ACC'),
            plotHandle(k).Color = [255,127,0] ./ 255;
        else
            plotHandle(k).Color = [31,120,180] ./ 255;
        end
    end
end


%% tSNE
colors = cell(length(curBrainAreas), 1);
[colors{ismember(curBrainAreas, 'ACC')}] =  deal([255,127,0] ./ 255);
[colors{ismember(curBrainAreas, 'dlPFC')}] =  deal([31,120,180] ./ 255);
colors = cat(1, colors{:});

numPCADim = 2;
perplexity = 15;
mappedX = tsne(parEst(~bad_ind, ~intercept_ind), colors, [], numPCADim, perplexity);