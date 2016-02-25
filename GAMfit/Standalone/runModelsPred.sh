#!/bin/sh
modelList[0]="s(Rule * Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule * Rule Repetition, Trial Time, knotDiff=50) + s(Rule * Congruency, Trial Time, knotDiff=50)"
modelList[1]="s(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50)"

numFiles=34;
# Time Period: Rule Response
timeperiod="Rule Response"
printf "\n\nProcessing Time Period: %s \n" "$timeperiod"

for (( i = 0; i < ${#modelList[@]}; i++ ))
do
  curModel="${modelList[$i]}"
  printf "\tProcessing Model: %s \n" "$curModel"
  # Update model list
  export CURMODEL="$curModel";
  modelCmd="gamParams.timePeriod = '$timeperiod'; \
  gamParams.regressionModel_str = getenv('CURMODEL'); \
  addpath('/projectnb/pfc-rule/Task-Switching-Analysis/Helper Functions'); \
  updateModelList(gamParams); exit;"

  matlab -nodisplay -r "$modelCmd"
  # Escape commas in model string with single quotes
  # because qsub splits passed variables with commas
  curModel=$(echo "$curModel" | sed -e "s/,/','/g")
  # Submit Cluster Jobs
  qsub -t "1-$numFiles" \
       -N GAMfit \
       -l h_rt=90:00:00 \
       -l mem_total=125G \
       -v MODEL="$curModel" \
       -v TIMEPERIOD="$timeperiod" \
       -v INCLUDETIMEBEFOREZERO="1" \
       -v OVERWRITE="0" \
       -v ISPREDICTION="1" \
       -v SMOOTHLAMBDA="10.^(-3:4)" \
       -v NUMCORES="5" \
       ./runGAMCluster2015a.sh;
done
