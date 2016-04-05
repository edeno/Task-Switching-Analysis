modelName = 'Rule * Previous Error + Rule * Rule Repetition';
timePeriod = 'Rule Stimulus';
[parEst, gam, neuronNames, neuronBrainAreas, p] = getCoef(modelName, timePeriod);
bad_ind = any(abs(parEst(:, 2:end)) > 5, 2);
neuronBrainAreas = neuronBrainAreas(~bad_ind);
neuronNames = neuronNames(~bad_ind);

%% PCA
[coeffs, score, latent, tSquared, explained, mu] = pca(parEst(~bad_ind, 2:end), 'centered', false);
figure;
plotHandle = biplot(coeffs(:,1:2), 'scores', score(:,1:2), ...
    'varlabels', gam.levelNames(2:end), ...
    'ObsLabels', cellfun(@(x,y) sprintf('%s %s', x, y), neuronBrainAreas, neuronNames, 'UniformOutput', false), ...
    'MarkerSize', 10);
for k = 1:length(plotHandle),
    if strcmp(plotHandle(k).Tag, 'obsmarker'),
        if strcmp(neuronBrainAreas(plotHandle(k).UserData), 'ACC'),
            plotHandle(k).Color = [255,127,0] ./ 255;
        else
            plotHandle(k).Color = [31,120,180] ./ 255;
        end
    end
end


%% tSNE
colors = cell(length(neuronBrainAreas), 1);
[colors{ismember(neuronBrainAreas, 'ACC')}] =  deal([255,127,0] ./ 255);
[colors{ismember(neuronBrainAreas, 'dlPFC')}] =  deal([31,120,180] ./ 255);
colors = cat(1, colors{:});

numPCADim = 2;
perplexity = 15;
mappedX = tsne(parEst(~bad_ind, 2:end), colors, [], numPCADim, perplexity);