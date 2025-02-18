# Running snakemake pipeline


## Put data in the right places

* Read files in `data/`
* the script `data/download_test_files.sh` will use `wget` to download some
DASSIM E. coli reads and a K12 reference for testing if you like

## Run 

`cd snakemake`  
`snakemake -s Snakemake_snippy.smk`  

It uses the `configJL.yaml` file and the data in the `data/` folder - put reads
in here

The `Snakefile` is sarah's full pipeline - fully working on 31/01/2025.

## Overview of pipeline - current pipeline

```mermaid
flowchart TB
A["{sample}{R1_suffix}.fastq
{sample}{R2_suffix}.fastq"] -->|snippy| B["{outputdir}/snps_out/{sample}-snps/"]
B --> C[snps.bam
*read mapping from bwa mem*]
B --> D[snps.raw.vcf
*variant calls from FreeBayes*]
D -->|split_complex_var| E[myfilt.vcf
*variants filtered on hetsnps, QUAL, depth as per snippy with bcftools and variants decomposed with vt*]
C -->|depth_calc| F[mydepth.tsv
*depth by site excluding low quality base and mapping quality*]
E -->|pull_out_var_calc| G[myVAF.tsv 
*VAF calculated using bcftools*]
D -->|high_qual_hetsnps| H[allSNPs.tsv
*all SNPs, filtered only for variant quaity ie QUAL decomposed and normalised with vt*]
```

Reminder

* QUAL - measure of variant quality used by bcftools
* samtools -q is base quality, -Q is mapping quality

## Proposed pipeline


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


