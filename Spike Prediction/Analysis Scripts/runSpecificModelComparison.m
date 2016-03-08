clear variables; close all;
files = { ...
    'pred_ACC_Rule Response_constant.mat', ...
    'pred_ACC_Stimulus Reward_constant.mat', ...
    'pred_dlPFC_Rule Response_constant.mat', ...
    'pred_dlPFC_Stimulus Reward_constant.mat', ...
    };
predictor = 'mutualInformation';
comparisonModel = {    'Rule * Previous Error + Response Direction'  };
modelsOfInterest = {...
    'Previous Error + Response Direction', ...
    'Previous Error + Response Direction + Rule * Rule Repetition', ...
    'Rule * Previous Error + Response Direction + Rule * Rule Repetition', ...
    'Rule * Previous Error + Response Direction + Rule * Congruency', ...
    'Rule * Previous Error + Response Direction + Rule * Rule Repetition + Rule * Congruency', ...
    };
for file_ind = 1:length(files),
  specificModelComparison(files{file_ind}, predictor, comparisonModel, modelsOfInterest)
end