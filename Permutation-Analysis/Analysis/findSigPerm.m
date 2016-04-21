rule_ind = ismember(comparisonNames, {'Orientation - Color'});

isACC = ismember({values.brainArea}, 'ACC');
isdlPFC = ismember({values.brainArea}, 'dlPFC');
ruleSig = h(rule_ind, :);

% ACC - prep period
neuronNames(isACC & ruleSig(1, :))
% ACC - stimulus period
neuronNames(isACC & ruleSig(2, :))
% ACC - both
neuronNames(isACC & ruleSig(1, :) & ruleSig(2, :))

% dlPFC - prep period
neuronNames(isdlPFC & ruleSig(1, :))
% dlPFC - stimulus period
neuronNames(isdlPFC & ruleSig(2, :))
% dlPFC - both
neuronNames(isdlPFC & ruleSig(1, :) & ruleSig(2, :))


%%
prevError_ind = ismember(comparisonNames, {'Previous Error - No Previous Error'});
prevErrorSig = h(prevError_ind, :);

% ACC - prep period
neuronNames(isACC & prevErrorSig(1, :))
% ACC - stimulus period
neuronNames(isACC & prevErrorSig(2, :))
% ACC - both
neuronNames(isACC & prevErrorSig(1, :) & prevErrorSig(2, :))

% dlPFC - prep period
neuronNames(isdlPFC & prevErrorSig(1, :))
% dlPFC - stimulus period
neuronNames(isdlPFC & prevErrorSig(2, :))
% dlPFC - both
neuronNames(isdlPFC & prevErrorSig(1, :) &prevErrorSig(2, :))

%%
ruleRep_ind = ismember(comparisonNames, {'Repetition1 - Repetition5+'});
ruleRepSig = h(ruleRep_ind, :);

% ACC - prep period
neuronNames(isACC & ruleRepSig(1, :))
% ACC - stimulus period
neuronNames(isACC & ruleRepSig(2, :))
% ACC - both
neuronNames(isACC & ruleRepSig(1, :) & ruleRepSig(2, :))

% dlPFC - prep period
neuronNames(isdlPFC & ruleRepSig(1, :))
% dlPFC - stimulus period
neuronNames(isdlPFC & ruleRepSig(2, :))
% dlPFC - both
neuronNames(isdlPFC & ruleRepSig(1, :) & ruleRepSig(2, :))

%%
response_ind = ismember(comparisonNames, {'Left - Right'});
responseSig = h(response_ind, :);

% ACC - response period
neuronNames(isACC & responseSig(1, :))
% ACC - reward period
neuronNames(isACC & responseSig(2, :))
% ACC - both
neuronNames(isACC & responseSig(1, :) & responseSig(2, :))

% dlPFC - response period
neuronNames(isdlPFC & responseSig(1, :))
% dlPFC - reward period
neuronNames(isdlPFC & responseSig(2, :))
% dlPFC - both
neuronNames(isdlPFC & responseSig(1, :) & responseSig(2, :))

