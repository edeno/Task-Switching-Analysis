#!/bin/sh
modelList[0]="Rule * Previous Error + Response Direction + Rule * Rule Repetition + Congruency"
modelList[1]="s(Rule * Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule * Rule Repetition, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50)"

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
       -l h_rt=96:00:00 \
       -l mem_total=125G \
       -v MODEL="$curModel" \
       -v TIMEPERIOD="$timeperiod" \
       -v INCLUDETIMEBEFOREZERO="1" \
       -v OVERWRITE="0" \
       -v SMOOTHLAMBDA="10.^(-2)" \
       -v NUMCORES="2" \
       ./runGAMCluster2015a.sh;
done
