load('paramSet.mat', 'colorInfo');
models = 'Rule + Previous Error History + Rule Repetition + Congruency + Response Direction';
timePeriods = 'Stimulus Response';
brainAreas = {'ACC', 'dlPFC'};
for area_ind = 1:length(brainAreas),
    [parEst, gam, ~, neuronBrainAreas, ~, h] = getCoef(models, timePeriods, 'isSim', false, 'brainArea', brainAreas{area_ind});
    bad_ind = abs(parEst) > 10;
    bad_ind(:, 1, :) = false;
    parEst(bad_ind) = NaN;
    
    sigMask = double(h);
    sigMask(sigMask ~= 1) = NaN;
    sigEst = sigMask .* parEst;
    
    covNames = gam.covNames;
    levelNames = gam.levelNames;
    
    getCov = @(cov) ismember(covNames, cov);
    
    %%
    f = figure;
    f.Name = brainAreas{area_ind};
    
    subplot(1,2,1);
    curCov = 'Previous Error History';
    plot(repmat(abs(parEst(:, getCov('Rule'))), [1, sum(getCov(curCov))]), abs(parEst(:, getCov(curCov))), '.', 'MarkerSize', 20, 'Color', [200, 200, 200] ./ 255);
    hold all;
    p = plot(repmat(abs(sigEst(:, getCov('Rule'))), [1, sum(getCov(curCov))]), abs(parEst(:, getCov(curCov))), '.', 'MarkerSize', 20);
    set(p, {'Color'}, values(colorInfo, levelNames(getCov(curCov)))');
    legend(p, levelNames(getCov(curCov)));
    title(curCov);
    ylim([0 2]);
    xlim([0 2]);
    refline;
    
    subplot(1,2,2);
    curCov = 'Rule Repetition';
    plot(repmat(abs(parEst(:, getCov('Rule'))), [1, sum(getCov(curCov))]), abs(parEst(:, getCov(curCov))), '.', 'MarkerSize', 20, 'Color', [200, 200, 200] ./ 255);
    hold all;
    p = plot(repmat(abs(sigEst(:, getCov('Rule'))), [1, sum(getCov(curCov))]), abs(sigEst(:, getCov(curCov))), '.', 'MarkerSize', 20);
    set(p, {'Color'}, values(colorInfo, levelNames(getCov(curCov)))');
    legend(p, levelNames(getCov(curCov)));
    title(curCov);
    ylim([0 2]);
    xlim([0 2]);
    refline;
    
end