# Region of Interest

Region of interest for mapping-based DJ estimation.

## References and required sequences

| Build       | Required sequences | Notes |
| ----------- | ------------------ | ----- |
| **T2T-CHM13 / hs1** | `chr13`, `chr14`, `chr15`, `chr21`, `chr22` | [Masked T2T-CHM13](https://s3-us-west-2.amazonaws.com/human-pangenomics/index.html?prefix=T2T/CHM13/assemblies/analysis_set/masked_DJ_rDNA_PHR_5S_wi_rCRS/), using all-but-one target masked, sample-matched [XX (chrY masked)](https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/masked_DJ_rDNA_PHR_5S_wi_rCRS/chm13v2.0_masked_DJ_5S_rDNA_PHR_noY_wi_rCRS.fa) or [XY (PAR masked)](https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/masked_DJ_rDNA_PHR_5S_wi_rCRS/chm13v2.0_masked_DJ_5S_rDNA_PHR_PAR_wi_rCRS.fa) sex chromosome compliment |
| **GRCh38 / hg38** | `chr21`, `chrUn_GL000220v1`, `chr17_GL000205v2_random`, `chr22_KI270733v1_random`, `chrUn_GL000195v1` | [Broad ver.](https://github.com/broadinstitute/gatk/tree/master/src/test/resources/large/) (UK Biobank) or [1KGP NYGC ver.](ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/GRCh38_reference_genome/GRCh38_full_analysis_set_plus_decoy_hla.fa) |
| **GRCh37 / hg19** *(experimental)* | `chr7_gl000195_random`, `chr17_gl000205_random` | [1KGP ver.](http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/) |


## File layout

Each per-reference subdirectory ships two kinds of BEDs used by
[scripts/calCounts.sh](../scripts/calCounts.sh):

- **Background** — autosomal intervals used to estimate coverage (denominator in
  `DJ_count = (2 × tgCount) / (covLen × bgCov)`).
- **Target** — DJ / rDNA / PHR intervals used to count on-target reads
  (numerator). The default target is `DJ_filt` (selectable via `--targetlist`).

Common file conventions:

| File | Purpose |
| ---- | ------- |
| `autosome.bed`, `autosome.len` | Autosomal intervals + total covered length. Used as the coverage background. |
| `autosome.nogap.bed`, `autosome.nogap.len` | Same, with assembly N-gaps excluded. Enabled by `--noGap true`. |
| `DJ*.bed`, `DJ*.len` | Target DJ intervals + covered length. |
| `PHR*.bed` | Target Pseudo Homolog Region. Reference material for filtering. |
| `rDNA*.bed`, `5S*.bed` | rDNA / 5S rDNA intervals (CHM13 only). |


### `CHM13/` — T2T-CHM13 v2.0 / hs1

A pilot, masked CHM13 fasta file was used to map reads and collect DJ copy count estimates. See [T2T-Ref](https://github.com/arangrhie/T2T-Ref) for more details.

- `autosome.bed`, `autosome.len` — background (no `.nogap` variant; T2T has no gaps).
- `DJ_on_chr13.bed`, `DJ_on_chr13.len` — **default target** for `--ref CHM13` (calCounts.sh auto-remaps `DJ_filt` → `DJ_on_chr13`).
- `chr13_PHR_arm1.bed`/`.len`, `chr13_PHR_arm2.bed`/`.len` — target PHR sub-region, less repetitive.
- `PHR_keep.bed`, `PHR_keep.len` — target PHR interval including both arms.
- `rDNA_18S.bed`, `rDNA_18S.len` — target 18S rDNA unit interval.
- `rDNA_keep.bed`, `rDNA_keep.len` — target rDNA unit interval.
- `keep_5S.bed`, `keep_5S.len` — 5S rDNA target interval.

### `GRCh38/` — GRCh38 / hg38 *(recommended)*

- `autosome.bed`, `autosome.len`, `autosome.nogap.bed`, `autosome.nogap.len` — background (with / without assembly gaps).
- `DJ.bed` — target DJ locus, not filtered.
- `DJ_filt.bed`, `DJ_filt.len`  — **default target**, filtered for coverage abnormalities. used by `--targetlist DJ_filt` (`DJ_filt.srt.bed` is the sorted version).
- `DJ_git.bed`, `DJ_git.len` — target used in the UKBioBank DJ counting described in ([Rhie et al.](https://doi.org/10.64898/2026.03.08.710242)).
- `ukb-dj.bed` — legacy, same as `DJ_git.bed`
- `PHR.bed` — Pseudo Homolog Region.
- `RA.bed` — Region A, leftover from other experiments.

### `hg19/` — GRCh37 / hg19 *(experimental)*

- `DJ.bed` — DJ locus.
- `ct_13_9.bed` — centromeric-transition region from the CenSat annotation within the DJ.
- `PHR.bed` — Pseudo Homolog Region.
- `5S_unit.bed`, `rDNA_unit.bed` — 5S rDNA unit annotations.

⚠️ `hg19` currently is left experimental, missing the background files
 (`autosome.bed`, `autosome.len`, `autosome.nogap.bed`, `autosome.nogap.len`)
