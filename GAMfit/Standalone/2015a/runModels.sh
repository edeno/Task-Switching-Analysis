#!/bin/sh
modelList=("s(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50)"
"s(Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50)")

runScript="./runGAMCluster2015a.sh"

# Time Period: Rule Response
timeperiod="Rule Response"
printf "\n\nProcessing Time Period: %s \n" "$timeperiod"

for (( i = 0; i < ${#modelList[@]}; i++ ))
do
  printf "\tProcessing Model: %s \n" "${modelList[$i]}"
  # Update model list
  matlab -nodisplay -r "gamParams.timePeriod = '$timeperiod'; \
  gamParams.regressionModel_str = '${modelList[$i]}'; \
  addpath('/projectnb/pfc-rule/Task-Switching-Analysis/Helper Functions'); \
  updateModelList(gamParams); exit;"
  # Submit Cluster Jobs
  qsub -t 1-2 \
       -N GAMfit \
       -l h_rt=24:00:00 \
       -l mem_total=125G \
       -v MODEL="${modelList[$i]}" \
       -v TIMEPERIOD="$timeperiod" \
       -v INCLUDETIMEBEFOREZERO="1" \
       -v SMOOTHLAMBDA="10.^(-3:4)" \
       -j y \
       "$runScript" \;
done
