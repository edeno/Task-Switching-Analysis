#!/bin/sh -l
# this script is a qsub companion script that's written explicitly
# to handle Array Jobs (-t) option for MATLAB standalone batch jobs.
# Similar to matlab -r ". . ." but more flexible
#
# Specify SGE batch scheduler options
# Merge output and error files in one
#$ -j y
#$ -o /usr3/graduate/edeno/logs/$JOB_NAME-$TASK_ID-$JOB_ID.log
#$ -pe omp 12

module load mcr/8.5_2015a

printf "\n\n---------\n"
printf "This job runs on %s" "$HOSTNAME"
printf "\n---------\n\n"

NODENAME=$(echo "$HOSTNAME" | sed 's/.scc.bu.edu//')

# Running MATLAB standalone results in creation of a cache folder
# in home dir which may cause runtime issues. Workaround below
printf "tmpdir is %s" "$TMPDIR"
export MCR_CACHE_ROOT=$TMPDIR
printf "\n\n---------\n"
printf "Created local scratch folder /net/%s%s" "$NODENAME" "$TMPDIR"
printf "\n---------\n\n"

unset DISPLAY

neuron_ind=$SGE_TASK_ID
COVOFINTEREST=${COVOFINTEREST?No covariate specified}
MODEL=${MODEL?No model specified}
TIMEPERIOD=${TIMEPERIOD?No time period specified}
OVERWRITE=${OVERWRITE:-"0"}

# Strip escaped commas ',' from the model string
MODEL=$(echo "$MODEL" | sed -e "s/','/,/g")

echo "Session Ind: $neuron_ind"
echo "Cov of Interest: $COVOFINTEREST"
echo "Model: $MODEL"
echo "Time Period: $TIMEPERIOD"
echo "Overwrite: $OVERWRITE"

./changePointExecR2015a "$neuron_ind" "$COVOFINTEREST" "$MODEL" "$TIMEPERIOD" \
"overwrite" "$OVERWRITE" \
