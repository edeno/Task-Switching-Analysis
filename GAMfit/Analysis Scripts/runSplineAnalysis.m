timePeriod = 'Rule Stimulus';
model = 's(Rule, Trial Time, knotDiff=50) + s(Previous Error, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50)';
[timeEst, time] = getSplineCoef(model, timePeriod, 'brainArea', 'ACC', 'isSim', true, 'subject', 'isa');

prevError = cat(4, timeEst.Previous_Error);
ruleRep = cat(4, timeEst.Rule_Repetition);
rule = cat(4, timeEst.Rule);

ruleRep(abs(ruleRep) > 10) = NaN;
rule(abs(rule) > 10) = NaN;
prevError(abs(prevError) > 10) = NaN;

stat = @(s) nanmean(s, 4);
bootEst = @(s) quantile(s, [0.025, 0.5, 0.975], 3);

est = squeeze(exp(bootEst(stat(ruleRep))));

if strcmp(unique({timeEst.subject}), 'isa'),
    bad_ind = time > 346;
    prevError = prevError(:, ~bad_ind, :, :);
    ruleRep = ruleRep(:, ~bad_ind, :, :);
    rule = rule(:, ~bad_ind, :, :);
    time = time(~bad_ind);
    est = est(:, ~bad_ind, :);
end

colorOrder =  [ ...
    228,26,28; ...
    199,233,180; ...
    127,205,187; ...
    65,182,196; ...
    199,233,180; ...
    ] ./ 255;

%%
figure;
subplot(1,3,1);
for k = 1:4,
    plot(time, squeeze(est(k, :, :)), 'Color', colorOrder(k, :), 'LineWidth', 2); hold all;
end
title('Rule Repetition');
xlim(quantile(time, [0 1]));
ylim([0.6 1.4]);
hline(1, 'Color', 'black', 'LineType', '-');
vline(0, 'Color', 'black', 'LineType', '-');


subplot(1,3,2);
plot(time, exp(squeeze(bootEst(stat(abs(rule))))));
title('Rule');
ylim([0.6 1.4]);
xlim(quantile(time, [0 1]));
vline(0, 'Color', 'black', 'LineType', '-');
hline(1, 'Color', 'black', 'LineType', '-');


subplot(1,3,3);
plot(time, exp(squeeze(bootEst(stat(prevError)))));
title('Previous Error');
ylim([0.6 1.4]);
xlim(quantile(time, [0 1]));
vline(0, 'Color', 'black', 'LineType', '-');
hline(1, 'Color', 'black', 'LineType', '-');
