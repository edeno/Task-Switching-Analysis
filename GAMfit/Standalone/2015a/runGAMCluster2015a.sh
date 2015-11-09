#!/bin/sh -l
# this script is a qsub companion script that's written explicitly
# to handle Array Jobs (-t) option for MATLAB standalone batch jobs.
# Similar to matlab -r ". . ." but more flexible
# Usage:
# scc1$ qsub -t 1-34 ./runGAMCluster # session_ind=1, 2, .. 34
#
# Specify SGE batch scheduler options
# Merge output and error files in one
#$ -pe omp 12

module load mcr/8.5

printf "\n\n********************************************"
printf "* This job runs on %s" "$HOSTNAME"
printf "********************************************\n\n"

NODENAME=$(echo "$HOSTNAME" | sed 's/.scc.bu.edu//')

# Running MATLAB standalone results in creation of a cache folder
# in home dir which may cause runtime issues. Workaround below
printf "tmpdir is %s" "$TMPDIR"
export MCR_CACHE_ROOT=$TMPDIR
printf "\n\n********************************************"
printf "* Created local scratch folder /net/%s%s" "$NODENAME" "$TMPDIR"
printf "********************************************\n\n"

unset DISPLAY

echo "$MODEL"

session_ind=$SGE_TASK_ID
MODEL=${MODEL?No model specified}
TIMEPERIOD=${TIMEPERIOD?No time period specified}
NUMFOLDS=${NUMFOLDS:-5}
PREDTYPE=${PREDTYPE:-"dev"}
SMOOTHLAMBDA=${SMOOTHLAMBDA:-"10^(-3)"}
RIDGELAMBDA=${RIDGELAMBDA:-"1"}
OVERWRITE=${OVERWRITE:-"0"}
INCLUDEFIXATIONBREAKS=${OVERWRITE:-"0"}
INCLUDETIMEBEFOREZERO=${OVERWRITE:-"0"}
ISPREDICTION=${ISPREDICTION:-"0"}

echo "Session Ind: $session_ind"
echo "Model: $MODEL"
echo "Time Period: $TIMEPERIOD"
echo "Number of Folds: $NUMFOLDS"
echo "Prediction Type: $PREDTYPE"
echo "Smooth Lambda: $SMOOTHLAMBDA"
echo "Ridge Lambda: $RIDGELAMBDA"
echo "Overwrite: $OVERWRITE"
echo "Include fixation breaks: $INCLUDEFIXATIONBREAKS"
echo "Include time before zero: $INCLUDETIMEBEFOREZERO"
echo "Prediction: $ISPREDICTION"

./GAMClusterExecR2015a "$session_ind" "$MODEL" "$TIMEPERIOD" \
"numFolds" "$NUMFOLDS" \
"predType" "$PREDTYPE" \
"smoothLambda" "$SMOOTHLAMBDA" \
"ridgeLambda"  "$RIDGELAMBDA" \
"overwrite" "$OVERWRITE" \
"includeFixationBreaks" "$INCLUDEFIXATIONBREAKS" \
"includeTimeBeforeZero" "$INCLUDETIMEBEFOREZERO" \
"isPrediction" "$ISPREDICTION"
