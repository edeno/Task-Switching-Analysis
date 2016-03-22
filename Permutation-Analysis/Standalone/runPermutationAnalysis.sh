#!/bin/sh
factorList[0]="Rule"
factorList[1]="Previous Error"
factorList[2]="Rule Repetition"
factorList[3]="Congruency"
numFiles=34;
# Time Period
timeperiod="Rule Stimulus"
printf "\n\nProcessing Time Period: %s \n" "$timeperiod"

for (( i = 0; i < ${#factorList[@]}; i++ ))
do
  curFactor="${factorList[$i]}"
  printf "\t\tProcessing Covariate: %s \n" "$curFactor"
  # Escape commas in model string with single quotes
  # because qsub splits passed variables with commas
  # Submit Cluster Jobs
  qsub -t "1-$numFiles" \
       -N "Perm_$curFactor" \
       -l h_rt=2:00:00 \
       -l mem_total=24G \
       -v TIMEPERIOD="$timeperiod" \
       -v COVARIATEOFINTEREST="$curFactor" \
       -v NUMCORES="12" \
       -v NUMRAND="10000" \
       ./runComputePermutationAnalysisExec2015a.sh;
done
