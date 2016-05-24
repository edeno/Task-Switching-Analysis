#!/bin/sh
curModel="s(Rule, Trial Time, knotDiff=50) + s(Previous Error History, Trial Time, knotDiff=50) + s(Rule Repetition, Trial Time, knotDiff=50) + s(Congruency, Trial Time, knotDiff=50)"
timeperiod="Rule Response"
covOfInterest[0]="Previous Error History"
covOfInterest[1]="Rule Repetition"
covOfInterest[2]="Congruency"

# Escape commas in model string with single quotes
# because qsub splits passed variables with commas
curModel=$(echo "$curModel" | sed -e "s/,/','/g")
numNeurons=575;
printf "\tProcessing Model: %s \n" "$curModel"
printf "\n\nProcessing Time Period: %s \n" "$timeperiod"

for (( i = 0; i < ${#covOfInterest[@]}; i++ ))
do
  curCov="${covOfInterest[$i]}"
  printf "\tCovariate of Interest: %s \n" "$curCov"
  # Submit Cluster Jobs
  qsub -t "1-$numNeurons" \
       -N changePoint \
       -l h_rt=1:00:00 \
       -l mem_total=24G \
       -v COVOFINTEREST="$curCov" \
       -v MODEL="$curModel" \
       -v TIMEPERIOD="$timeperiod" \
       -v OVERWRITE="0" \
       ./runChangePoint2015a.sh;
done
