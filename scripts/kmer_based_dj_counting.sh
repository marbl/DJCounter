#!/usr/bin/env bash

while [[ $# -gt 0 ]]; do
    case "$1" in
        -sample)
            sample="$2"
            shift 2
            ;;
        -input)
            input="$2"
            shift 2
            ;;
        -tmp)
            tmp="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
    esac
done

if [[ -z $sample || -z $input ]]; then
  echo "Usage: kmer_based_dj_counting.sh -sample <sample_name> -input <input.bam|input.cram|input.fq.gz> -tmp <tmp_dir>"
  echo "  sample_name: Sample identifier"
  echo "  input.bam|input.cram|input.fq.gz: Input sequencing reads in BAM or FASTQ format (gz or not)."
  echo "  For paired-end reads, provide files as a comma separated list e.g. \"input1.fq.gz,input2.fq.gz\""
  echo "  tmp_dir: Temporary directory for intermediate files. DEFAULT: /lscratch/\$SLURM_JOB_ID or /tmp"
  exit 1
fi

# Locate the DJ target k-mer database.
# 1) Sibling to the script (source checkout layout: scripts/../resources/...).
# 2) Conda package data dir (bioconda layout: $CONDA_PREFIX/share/djcounter/resources/...).
# 3) Environment override: $DJ_TARGET already set by the caller.
if [[ -z "$DJ_TARGET" ]]; then
  _script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  for _cand in \
      "$_script_dir/../resources/DJtarget.meryl" \
      "${CONDA_PREFIX:-}/share/djcounter/resources/DJtarget.meryl"; do
    if [[ -d "$_cand" ]]; then
      DJ_TARGET="$_cand"
      break
    fi
  done
fi
if [[ ! -d "$DJ_TARGET" ]]; then
  echo "ERROR: cannot locate DJtarget.meryl. Set \$DJ_TARGET or unpack resources/DJtarget.meryl.tar.gz." >&2
  exit 1
fi

# Locate the Merqury kmerHistToPloidyDepth.jar.
# 1) Explicit $MERQURY (matches historical usage).
# 2) Bioconda merqury layout: $CONDA_PREFIX/share/merqury.
# 3) Sibling of the merqury.sh entry point on $PATH.
if [[ -z "$MERQURY" || ! -f "$MERQURY/eval/kmerHistToPloidyDepth.jar" ]]; then
  for _cand in \
      "${CONDA_PREFIX:-}/share/merqury" \
      "$(dirname "$(command -v merqury.sh 2>/dev/null)" 2>/dev/null)/../share/merqury"; do
    if [[ -f "$_cand/eval/kmerHistToPloidyDepth.jar" ]]; then
      MERQURY="$_cand"
      break
    fi
  done
fi
if [[ -z "$MERQURY" || ! -f "$MERQURY/eval/kmerHistToPloidyDepth.jar" ]]; then
  echo "ERROR: cannot locate kmerHistToPloidyDepth.jar. Set \$MERQURY to your merqury clone or 'conda install -c bioconda merqury'." >&2
  exit 1
fi

cpus=$SLURM_CPUS_PER_TASK
if [ -z "$cpus" ]; then
  cpus=24
fi

if [[ -z $SLURM_MEM_PER_NODE ]]; then
  mem=48
else
  # Convert MB to GB
  mem=$(((SLURM_MEM_PER_NODE/1024)-10))
fi

if [[ -z $tmp ]]; then
  if [[ -z $SLURM_JOB_ID ]]; then
    mkdir -p tmp
    tmp="tmp"
  else
    tmp="/lscratch/$SLURM_JOB_ID"
  fi
fi

if [[ -s DJcounts/${sample}_DJ_count.txt ]]; then
  echo "DJ count file already exists for ${sample}. Nothing to do."
  exit 0
fi

set -e
set -o pipefail
set -x

mkdir -p hist DJcounts

if [[ -d $tmp/${sample}.k31.meryl ]]; then
  echo "Kmer database already exists for ${sample}, skipping counting."
else
  input=$(echo $input | tr ',' ' ')
  echo "Counting kmers for ${sample} from ${input}"
	if ! [[ -s $input ]]; then
	  echo "$input file is empty."
	  exit 1
	fi
  meryl count k=31 threads=${cpus} memory=${mem} output $tmp/${sample}.k31.meryl ${input}
  meryl histogram $tmp/${sample}.k31.meryl > hist/${sample}.k31.hist
fi

if [[ -s hist/${sample}.DJ.hist ]]; then
  echo "DJ meryl already exists for ${sample}, skipping intersect."
else
  meryl intersect threads=${cpus} memory=${mem} \
    $tmp/${sample}.k31.meryl $DJ_TARGET output hist/${sample}.DJ.meryl
fi
meryl histogram hist/${sample}.DJ.meryl  > hist/${sample}.DJ.hist

count_mid=`cat hist/${sample}.DJ.hist | awk '{ count+=$NF; } END {print count/2}'`
med=`cat hist/${sample}.DJ.hist | \
  awk -v count_mid=${count_mid} '{cnt_sum+=$NF; if (cnt_sum > count_mid) {print $(NF-1); exit;} }'`

peak2=`java -jar -Xmx256m $MERQURY/eval/kmerHistToPloidyDepth.jar hist/${sample}.k31.hist |\
  tail -n1 | awk '{print $2}'`

# print Sample, DJmedCov, PeakCP2, Peak_Est
echo -e "${sample}\t${med}\t${peak2}" |
  awk -F "\t" '{print $1"\t"$2"\t"$3"\t"(($2*2)/$3)}' \
  > DJcounts/${sample}_DJ_count.txt

cat DJcounts/${sample}_DJ_count.txt
