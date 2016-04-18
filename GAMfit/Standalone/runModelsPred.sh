#!/bin/sh
modelList[0]="Rule + Previous Error + Rule Repetition + Test Stimulus"
modelList[1]="Rule + Previous Error + Rule Repetition + Congruency"

numFiles=34;
# Time Period
timeperiod="Rule Stimulus"
printf "\n\nProcessing Time Period: %s \n" "$timeperiod"

for (( i = 0; i < ${#modelList[@]}; i++ ))
do
  curModel="${modelList[$i]}"
  printf "\tProcessing Model: %s \n" "$curModel"
  # Update model list
  export CURMODEL="$curModel";
  modelCmd="gamParams.timePeriod = '$timeperiod'; \
  gamParams.regressionModel_str = getenv('CURMODEL'); \
  addpath('/projectnb/pfc-rule/Task-Switching-Analysis/Helper-Functions'); \
  updateModelList(gamParams); exit;"

  matlab -nodisplay -r "$modelCmd"
  # Escape commas in model string with single quotes
  # because qsub splits passed variables with commas
  curModel=$(echo "$curModel" | sed -e "s/,/','/g")
  # Submit Cluster Jobs
  qsub -t "1-$numFiles" \
       -N GAMpred \
       -l h_rt=1:00:00 \
       -l mem_total=24G \
       -v MODEL="$curModel" \
       -v TIMEPERIOD="$timeperiod" \
       -v INCLUDETIMEBEFOREZERO="0" \
       -v OVERWRITE="0" \
       -v ISPREDICTION="1" \
       -v RIDGELAMBDA="0" \
       -v SMOOTHLAMBDA="10.^(-2)" \
       -v NUMCORES="12" \
       ./runGAMCluster2015a.sh;
done
