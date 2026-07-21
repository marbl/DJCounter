<h1 align="center">🧬 DJCounter</h1>

<p align="center">
  <em>Estimate the copy number of ribosomal-DNA distal junctions (DJs) from sequencing data.</em>
</p>

---

## Overview

`DJCounter` estimates how many copies of the ribosomal-DNA **distal junction (DJ)** are present in a human genome from short-read sequencing data. It supports two complementary modes:

| Mode | Input | When to use |
| ---- | ----- | ----------- |
| **Mapping-based** | aligned BAM/CRAM | reads already aligned to GRCh38 / GRCh37 / CHM13|
| **K-mer based** *(reference-free)* | raw FASTQ (or BAM/CRAM) | raw reads or BAM file |

- Mapping-based: DJ copy number is derived from sequencing **coverage** in the target region, normalized to autosomal background.
- K-mer based: DJ copy number is derived from the **k-mer multiplicity** of a curated DJ-specific 31-mer set, normalized to the 2-copy peak in the read k-mer histogram.

Typical human samples yield ~10 DJ copies and Robertsonian samples typically show ~8.

## Quick start

### 1. Mapping-based

Suitable when your BAM/CRAM is aligned to one of the supported references (see [References](#supported-references)).

```bash
scripts/calCounts.sh \
    --sample  Sample01 \
    --bam     /path/to/sample.bam \
    --ref     GRCh38 \
    --threads 10
```

Output: `$outdir/$sample.$ref.tg.<filter>.<gap>.txt`

```
sample      ref     roi      DJ_count
Sample01    GRCh38  DJ_filt  11.01608
```

📘 Details: [scripts/mapping_based.md](scripts/mapping_based.md)

### 2. K-mer based (reference-free)

```bash
# 1. Prepare the DJ target k-mer database (one-time)
cd resources
pigz -cd DJtarget.meryl.tar.gz | tar -xf -

# 2. Run on a sample
scripts/kmer_based_dj_counting.sh Sample01 /path/to/reads.fq.gz
# or paired-end:
scripts/kmer_based_dj_counting.sh Sample01 reads_1.fq.gz,reads_2.fq.gz
# or BAM/CRAM:
scripts/kmer_based_dj_counting.sh Sample01 sample.bam
```

Plot the distribution across many samples:

```bash
cat DJcounts/*_DJ_count.txt > DJ_counts.txt
Rscript scripts/plot_dist.R
```

📘 Details: [scripts/kmer_based.md](scripts/kmer_based.md)

## How it works

### Mapping-based

```
DJ_count = (2 × tgCount) / (covLen × bgCov)

  tgCount : reads aligned to the DJ target regions
  covLen  : DJ length on CHM13 used to normalize tgCount
  bgCov   : background autosomal coverage
```

### K-mer based

1. Count all 31-mers in the input (`meryl count k=31`).
2. Intersect with the curated `DJtarget.meryl` set (52,227 distinct k-mers; 26,140,589 occurrences) and read the median frequency from its histogram.
3. Use Merqury's `kmerHistToPloidyDepth.jar` to estimate the 2-copy peak from the read k-mer histogram.
4. `DJ_count ≈ DJ_median / (peak2 / 2)`.

## Supported references for mapping-based counting

| Build       | Required contigs                                                                                          | Notes |
| ----------- | --------------------------------------------------------------------------------------------------------- | ----- |
| **GRCh38 / hg38** | `chr21`, `chrUn_GL000220v1`, `chr17_GL000205v2_random`, `chr22_KI270733v1_random`, `chrUn_GL000195v1` | [Broad ver.](https://github.com/broadinstitute/gatk/tree/master/src/test/resources/large/) (UK Biobank) or [1KGP NYGC ver.](ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/GRCh38_reference_genome/GRCh38_full_analysis_set_plus_decoy_hla.fa) |
| **GRCh37 / hg19** *(experimental)* | `chr7_gl000195_random`, `chr17_gl000205_random` | [1KGP ver.](http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/) |
| **T2T-CHM13 / hs1** | `chr13`, `chr14`, `chr15`, `chr21`, `chr22` | |

Verify your BAM contains the required contigs:

```bash
samtools view -H sample.bam | grep chr17_GL000205v2_random
```

## Repository layout

```
DJCounter/
├── scripts/         # Pipeline scripts and per-mode docs
│   ├── calCounts.sh
│   ├── kmer_based_dj_counting.sh
│   ├── mapping_based.md
│   └── kmer_based.md
├── resources/       # Pre-built DJ k-mer database & references
│   └── DJtarget.meryl.tar.gz
├── roi/             # Target BED files
│   ├── GRCh38/
│   ├── hg19/
│   └── CHM13/
└── paper/           # jupyter notebook for generating plots
```

## Dependencies

- [`samtools`](https://www.htslib.org/) ≥ 1.21 — mapping-based mode
- [`meryl`](https://github.com/marbl/meryl) ≥ 1.4.2 — k-mer mode
- [`merqury`](https://github.com/marbl/merqury) — only `eval/kmerHistToPloidyDepth.jar`; set `$MERQURY` to the clone path
- Java runtime (for the Merqury jar)
- `pigz`, `R` (for plotting)

## Changelog

| Version | Date | Changes |
| ------- | ---- | ------- |
| **v1.0** | 2026-03-08 | Finalized hg38 and k-mer modes |
| v0.2.2  | 2025-11-26 | Added BED file for ROI on hg19 |
| v0.2.1  | 2024-07-29 | Output background and fragment size; fixed background command |
| v0.2    | 2024-07-25 | `samtools idxstats` → `samtools coverage` for background; removed temp files |
| v0.1    | 2024-07-17 | First commit |
