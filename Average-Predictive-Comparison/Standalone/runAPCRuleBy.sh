#!/bin/sh
model="Rule * Previous Error + Rule * Rule Repetition"
# Escape commas in model string with single quotes
# because qsub splits passed variables with commas
curModel=$(echo "$model" | sed -e "s/,/','/g")
printf "\tProcessing Model: %s \n" "$curModel"
factorList[0]="Previous Error"
factorList[1]="Rule Repetition"
numFiles=34;
# Time Period
timeperiod="Rule Stimulus"
printf "\n\nProcessing Time Period: %s \n" "$timeperiod"

for (( i = 0; i < ${#factorList[@]}; i++ ))
do
  curFactor="${factorList[$i]}"
  printf "\t\tProcessing Factor: %s \n" "$curFactor"
  # Submit Cluster Jobs
  qsub -t "1-$numFiles" \
       -N "APC_RuleBy$curFactor" \
       -l h_rt=3:00:00 \
       -l mem_total=48G \
       -v MODEL="$curModel" \
       -v TIMEPERIOD="$timeperiod" \
       -v FACTOROFINTEREST="$curFactor" \
       -v NUMCORES="12" \
       -v ISWEIGHTED="0" \
       ./runComputeAPCRuleBy2015a.sh;
done
