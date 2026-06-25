#!/bin/bash

if [[ "$#" -lt 4 ]] ; then
  echo "Usage: ./_submit_minimap2.sh ref.fasta prefix input.fofn map_opt [extra]"
  echo "  ref.fasta   reference to align"
  echo "  prefix      output prefix"
  echo "  input.fofn  file of filenames containing reads to map"
  echo "  map_opt     mapping mode options. -x map-hifi for HiFi, -x map-ont for ONT, -x map-pb for CLR."
  echo "              -y for adding methylation tags. lr:hq for high-quality long reads. See minimap2 manual for details."
  echo "  extra       additional sbatch options. e.g. --dependency=afterok:12345"
  exit -1
fi

ref=$1
prefix=$2
input=$3
map_opt=$4
extra=$5 # "--dependency=afterok:$jid"

PIPELINE=$tools/DJCounter/scripts/mapping_longreads

echo $opt

path=`pwd`
mkdir -p logs

ln -sf $ref
ref=`basename $ref`

set -o pipefail

cpus=24
mem=60g
partition=norm
walltime=2-0
name=map.$prefix
log=logs/$name.%A_%a.log
script=$PIPELINE/map.sh
# args="$ref $map $opt"

echo $args
LEN=`wc -l $input | awk '{print $1}'`
arr=""
for i in $(seq 1 $LEN)
do
  reads=`sed -n ${i}p $input`

  out=`basename $reads`
  out=`echo $out | sed 's/.gz$//g'`
  out=`echo $out | sed 's/.fasta$//g' | sed 's/.fa$//g'`
  out=`echo $out | sed 's/.fastq$//g' | sed 's/.fq$//g'`
  out=$out.$i

  if ! [[ -s $out.sort.bam ]] ; then
    arr="${arr}${i}_"
  fi
done

# bash does not understand commas (,), so let's use _
if [[ "$arr" == "" ]]; then
  echo "Found all *.sort.bam. Skip mapping"
else
  # add 500g local sractch, include job dependency if provided, and set array
  arr=`echo $arr | sed 's/_/,/g'`
  extra="$extra --gres=lscratch:500 --array=$arr"

  set -x
  sbatch -J $name --cpus-per-task=$cpus --mem=$mem --partition=$partition -D `pwd` $extra --time=$walltime --error=$log --output=$log $script $ref $input "$map_opt" > map.jid
  set +x
  cat map.jid
fi

# Merge
cpus=48
mem=60g
partition=norm
walltime=1-0
name=merge.$prefix
script=$PIPELINE/merge.sh
args="$prefix"

jid=`cat map.jid`
extra="--dependency=afterok:$jid"
log=logs/$name.%A.log

set -x
sbatch -J $name --cpus-per-task=$cpus --mem=$mem --partition=$partition -D `pwd` $extra --time=$walltime --error=$log --output=$log $script $args > merge.jid
set +x

cpus=12
mem=8g
name=filt.$prefix
log=logs/$name.%A.log
script=$PIPELINE/filt.sh
args="$prefix.bam"

jid=`cat merge.jid`
extra="--dependency=afterok:$jid"
set -x
sbatch -J $name --cpus-per-task=$cpus --mem=$mem --partition=$partition -D `pwd` $extra --time=$walltime --error=$log --output=$log $script $args > filt.jid
set +x
cat filt.jid
