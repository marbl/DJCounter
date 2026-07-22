#! /bin/bash

if [[ "$#" -lt 1 ]]; then
  echo "Usage: sh _submit_kmer_based_dj_counting_jobs.sh sample_input.map [-array array_idx]"
  echo "  sample_input.map: Tab-delimited file with sample name and input file(s) in one line"
  echo "                    Format: <sample_name> <input.bam|input.cram|input1.fq.gz(,input2.fq.gz)*>"
  echo "  -array: (optional) Comma separated list of line numbers to submit as array job."
  exit -1
fi


# Default values
map=$1
shift 1

array_idx=""

while [[ $# -gt 0 ]]; do
    case "$1" in
            -array)
            array_idx="$2"
            shift 2
            ;;
        *)
            # Handle non-option arguments or break the loop
            echo "Unknown option: $1"
            exit 1
    esac
done


args="$map"

NUM_LINES=`wc -l $map | awk '{print $1}'`
array="--array=1-$NUM_LINES"
if [ -n "$array_idx" ]; then
    echo "Array job indices: $array_idx"
    array="--array=$array_idx"
fi

cpus=16
mem=120g # Offsetting 10G in kmer_base_dj_counting.sh to prevent out of memory error in case of slight underestimation of memory requirement.
name=kmer_dj_count
script=$tools/DJCounter/scripts/_kmer_based_dj_counting_job.sh
args="$args"
partition=quick
walltime=4:00:00
path=`pwd`
local="--gres=lscratch:100" # increase for higher cov. ONT data. 300-1200

mkdir -p logs
log=logs/$name.%A_%a.log

set -x
sbatch -J $name \
  --cpus-per-task=$cpus --mem=$mem \
  --partition=$partition \
  $array $local \
  -D $path --time=$walltime --error=$log \
  --output=$log $script $args

