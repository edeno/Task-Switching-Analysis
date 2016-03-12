#!/bin/sh
model="s(Rule * Previous Error, Trial Time, knotDiff=50) + s(Response Direction, Trial Time, knotDiff=50) + s(Rule * Rule Repetition, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50)"
# Escape commas in model string with single quotes
# because qsub splits passed variables with commas
curModel=$(echo "$model" | sed -e "s/,/','/g")
printf "\tProcessing Model: %s \n" "$curModel"
factorList[0]="Previous Error"
factorList[1]="Rule Repetition"
numFiles=34;
# Time Period
timeperiod="Rule Response"
printf "\n\nProcessing Time Period: %s \n" "$timeperiod"

for (( i = 0; i < ${#factorList[@]}; i++ ))
do
  curFactor="${factorList[$i]}"
  printf "\t\tProcessing Factor: %s \n" "$curFactor"
  # Submit Cluster Jobs
  qsub -t "1-$numFiles" \
       -N "APC_RuleBy$curFactor" \
       -l h_rt=24:00:00 \
       -l mem_total=124G \
       -v MODEL="$curModel" \
       -v TIMEPERIOD="$timeperiod" \
       -v FACTOROFINTEREST="$curFactor" \
       -v NUMCORES="2" \
       -v ISWEIGHTED="0" \
       ./runComputeAPCRuleBy2015a.sh;
done
