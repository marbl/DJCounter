#!/bin/bash

if [ -z $1 ]; then
  echo "Usage: merge.sh <out_prefix>"
  exit -1
fi

prefix=$1

module load samtools/1.23 # load v1.15.1 or higher

set -x
samtools merge -O bam -@$SLURM_CPUS_PER_TASK --write-index $prefix.bam *.sort.bam
set +x
