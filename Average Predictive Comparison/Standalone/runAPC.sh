#!/bin/sh
curModel="s(Rule * Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule * Rule Repetition, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50)"
factorList[0]="Rule"
factorList[1]="Previous Error"
factorList[2]="Response Direction"
factorList[3]="Rule Repetition"
factorList[4]="Congruency"
numFiles=34;
# Time Period
timeperiod="Rule Response"
printf "\n\nProcessing Time Period: %s \n" "$timeperiod"

for (( i = 0; i < ${#factorList[@]}; i++ ))
do
  curFactor="${factorList[$i]}"
  printf "\tProcessing Model: %s \n" "$curModel"
  printf "\t\tProcessing Factor: %s \n" "$curFactor"
  # Escape commas in model string with single quotes
  # because qsub splits passed variables with commas
  curModel=$(echo "$curModel" | sed -e "s/,/','/g")
  # Submit Cluster Jobs
  qsub -t "1-$numFiles" \
       -N GAMfit \
       -l h_rt=24:00:00 \
       -l mem_total=80G \
       -v MODEL="$curModel" \
       -v TIMEPERIOD="$timeperiod" \
       -v CURFACTOR="$curFactor" \
       -v NUMCORES="12" \
       ./runComputeAPC2015a.sh;
done
