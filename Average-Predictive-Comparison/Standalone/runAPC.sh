#!/bin/sh
curModel="Rule * Previous Error + Response Direction + Rule * Rule Repetition + Congruency"
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
       -N "APC_$curFactor" \
       -l h_rt=24:00:00 \
       -l mem_total=80G \
       -v MODEL="$curModel" \
       -v TIMEPERIOD="$timeperiod" \
       -v FACTOROFINTEREST="$curFactor" \
       -v NUMCORES="12" \
       -v ISWEIGHTED="0" \
       ./runComputeAPC2015a.sh;
done