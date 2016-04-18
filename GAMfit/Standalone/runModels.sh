#!/bin/sh
modelList[0]="Rule * Previous Error History + Session Time"
modelList[1]="Rule * Previous Error History"

numFiles=34;
timeperiod="Intertrial Interval"
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
       -N GAMfit \
       -l h_rt=1:00:00 \
       -l mem_total=24G \
       -v MODEL="$curModel" \
       -v TIMEPERIOD="$timeperiod" \
       -v INCLUDETIMEBEFOREZERO="0" \
       -v OVERWRITE="0" \
       -v SMOOTHLAMBDA="10.^(-2)" \
       -v RIDGELAMBDA="0" \
       -v NUMCORES="12" \
       ./runGAMCluster2015a.sh;
done
