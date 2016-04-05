#!/bin/sh
numFiles=34;
qsub -t "1-$numFiles" \
     -N "convertSpikestoJSON" \
     -l h_rt=2:00:00 \
     -l mem_total=24G \
     ./runComputeSpikesToJSONExec2015a.sh;
