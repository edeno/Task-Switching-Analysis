#!/bin/sh -l
# this script is a qsub companion script that's written explicitly
# to handle Array Jobs (-t) option for MATLAB standalone batch jobs.
# Similar to matlab -r ". . ." but more flexible
# Usage:
# scc1$ qsub -t 1-32 ./runGAMCluster2013a.sh # session_ind=1,2, .. 32
#
# Specify SGE batch scheduler options
# Merge output and error files in one
#$ -j y
#$ -pe omp 12
# Give the job(s) a name
#$ -N GAMfit

module load mcr/8.1

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

echo $LD_LIBRARY_PATH

session_ind=$SGE_TASK_ID

MODEL="Rule"
echo "Model: $MODEL"
TIMEPERIOD="Rule Response"
echo "Time Period: $TIMEPERIOD"
echo "Session Ind: $session_ind"

./GAMClusterExecR2013a "$session_ind" "$MODEL" "$TIMEPERIOD"