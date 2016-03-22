#!/bin/sh -l
# this script is a qsub companion script that's written explicitly
# to handle Array Jobs (-t) option for MATLAB standalone batch jobs.
# Similar to matlab -r ". . ." but more flexible
# Usage:
# scc1$ qsub -t 1-34 ./runGAMCluster # session_ind=1, 2, .. 34
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

session_ind=$SGE_TASK_ID
TIMEPERIOD=${TIMEPERIOD?No time period specified}
COVARIATEOFINTEREST=${COVARIATEOFINTEREST?No factor specified}
NUMRAND=${NUMRAND:-"10000"}
OVERWRITE=${OVERWRITE:-"0"}
NUMCORES=${NUMCORES:-"12"}

echo "Session Ind: $session_ind"
echo "Time Period: $TIMEPERIOD"
echo "Factor of Interest: $FACTOROFINTEREST"
echo "Number of Permutations: $NUMRAND"
echo "Overwrite: $OVERWRITE"
echo "Number of Cores: $NUMCORES"

./computePermutationAnalysisExecR2015a "$session_ind" "$COVARIATEOFINTEREST" "$TIMEPERIOD" \
"numRand" "$NUMRAND" \
"overwrite" "$OVERWRITE" \
"numCores" "$NUMCORES"
