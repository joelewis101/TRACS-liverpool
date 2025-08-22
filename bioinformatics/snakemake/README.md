# Running snakemake pipeline

Currently the pipeline takes a folder full of pick reads, a folder full of sweep
reads, assembles them to a reference with snippy. Then uses the bam files to
generate masks for low quality (QUAL) variants, low depth (accounting for poor
quality bases  and mappings) and heterogeneous SNPS (!= "1/1") in bases. It
produces an output tsv with a list of high quality variants that are present is
either picks, sweeps, or both.

## Problems to fix in the pipeline

Use the spike experiments as test data 

* There are SNPs being called between the spike picks (~ 20) which are not
present in the snippy consensus sequences - filtering must be wrong somewhere
* Since implementing depth filter, all the SNPs in the core picks have gone -
which must be wrong as the snippy consensus sequencers show they are there
* Depth fitering in the problematic snps filter isn't adding them to the masks
so would ovecall differences between picks and sweeps (extra SNPs in picks)

What we expect

* ST131 spike - 5 picks with 0 SNPs between 

## Put data in the right places

* Read files in `data/`
* sweeps in `data/sweeps`, picks in `data/picks`

## Run 

`snakemake`  

Reminder

* QUAL - measure of variant quality used by bcftools
* samtools -q is base quality, -Q is mapping quality

## Pipeline overview
```mermaid
flowchart TB
a["Sweeps/ 
{sample}{R1_suffix}.fastq
{sample}{R2_suffix}.fastq"] -->|snippy| B
A["Picks/ 
{sample}{R1_suffix}.fastq
{sample}{R2_suffix}.fastq"] -->|snippy| B["{outputdir}/snps_out/{sample}-snps/"]
B --> C[snps.bam
*read mapping from bwa mem*]
B --> D[snps.raw.vcf
*variant calls from FreeBayes*]
D -->|low_QUAL_variants| E[low_QUAL_variants.vcf
*all variants with mapping QUAL below threshold to mask in downstream analysis*]
C -->|samtools_depth_calc| F[samtoools_depth.tsv
*depth by site excluding low quality base and mapping quality to mask in downstream analysis*]
D -->|het_variants| G[het_variants.tsv 
*all het ie not 1/1 genotype variants to mask in pick analysis, as snippy would do*]
D -->|high_qual_variants| H[high_QUAL_variants.tsv
*all variants, filtered only for variant quaity ie QUAL and depth as per snippy, decomposed and normalised with vt including the necessary fields to calculate VAF*]
E -->|generate_mask| I[sites_to_mask.tsv
*bases to mask in downstream analysis:*

*-  if PICK then all sites with depth < 20 in samtools_depth.tsv, and all variants in low_QUAL_variants.tsv and het_variants.tsv*

*- if SWEEP then the same but don't include het_variants.tsv in mask*]
G -->|generate_mask| I
F -->|generate_mask| I
I -->|combine_pick_mask| J[all_pick_sites_to_mask.tsv
*combined deduplicated sites to mask from all picks*]
H -->|combine_pick_variants| K[all_pick_variants.tsv
*combined deduplicated variants from all picks*]
K -->|compare_snps_pick_and_sweep| L[pick_vs_sweep_snps.tsv
*SNPs only and whether they are present in pick, sweep, or both*]
H -->|compare_snps_pick_and_sweep| L
I -->|compare_snps_pick_and_sweep| L
J -->|compare_snps_pick_and_sweep| L

```


