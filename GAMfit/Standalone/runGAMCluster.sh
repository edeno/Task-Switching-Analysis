#!/bin/csh
# this script is a qsub companion script that's written explicitly
# to handle Array Jobs (-t) option for MATLAB standalone batch jobs.
# Similar to matlab -r ". . ." but more flexible
# Usage:
# scc1$ qsub -t 1-32 ./runGAMCluster # session_ind=1,2, .. 32
#
# Specify SGE batch scheduler options
# Merge output and error files in one
#$ -j y
#$ -pe omp 12
# set default value for n; override with qsub -v or -t at runtime
#$ -v session_ind=1
# Give the job(s) a name
#$ -N GAMfit

echo "\n\n********************************************"
echo "* This job runs on $HOSTNAME"
echo "********************************************\n\n"

set NODENAME = `echo $HOSTNAME | sed 's/.scc.bu.edu//'`

# Running MATLAB standalone results in creation of a cache folder
# in home dir which may cause runtime issues. Workaround below
echo tmpdir is $TMPDIR
setenv MCR_CACHE_ROOT $TMPDIR
echo "\n\n********************************************"
echo "* Created local scratch folder /net/$NODENAME$TMPDIR"
echo "********************************************\n\n"

unsetenv DISPLAY

if $?SGE_TASK_ID then
  @ session_ind = $SGE_TASK_ID
endif
echo "Session ind: $session_ind"

set MODEL = "Rule"
echo "Model: $MODEL"
set TIMEPERIOD = "Rule Response"
echo "Time Period: $TIMEPERIOD"

./GAMClusterExecR2013a $session_ind $MODEL $TIMEPERIOD
