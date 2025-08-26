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
D -->|low_QUAL_var| E[low_QUAL_variants.vcf
*all variants wieth variant QUAL below threshold to mask in downstream analysis*]
C -->|samtools_depth_calc| F[samtoools_depth.tsv
*depth by site excluding low quality base and mapping quality to mask in downstream analysis*]
D -->|het_var| G[het_variants.tsv 
*all het ie not 1/1 genotype variants to mask in pick analysis, as snippy would do*]
D -->|high_qual_variants| H[high_QUAL_variants.tsv
*all variants, filtered only for variant quaity ie QUAL, decomposed and normalised with vt including the necessary fields to calculate VAF*]
E -->|generate_pick_masks| I[sites_to_mask.tsv
*bases to mask in downstream analysis:*

*-  if PICK then all sites with depth < 20 in samtools_depth.tsv, and all variants in low_QUAL_variants.tsv and het_variants.tsv*

*- if SWEEP then the same but don't include het_variants.tsv in mask*]
G -->|generate_pick_mask| I
F -->|generate_pick_mask| I
I -->|concat_masks| J[concat_mask.tsv
*combined deduplicated sites to mask from all samples - picks and sweeps*]
H -->|concat_pick_vars| K[concat_decomposed_pick_vars_unmasked.tsv
concat_decomposed_sweeps_vars_unmasked
*combined deduplicated variants from all picks/sweeps*]
H -->|concat_sweep_vars| K
K -->|combine_and_mask_pick_and_sweep_vars| L[pick_vs_sweep_variants.tsv
*SNPs only and whether they are present in pick, sweep, or both*]
J -->|combine_and_mask_pick_and_sweep_vars| L




H -->|filter_problem_variants| M[problem_snps.tsv]
M -->|add_problem_snps_to_mask| O[sites_to_mask_filt.tsv]
I -->|add_problem_snps_to_mask| O[sites_to_mask_filt.tsv]
H -->|filter_problem_variants| N[high_QUAL_variants_filtered.tsv]

O -->|combine_and_mask_pick_and_sweep_vars_filt| P[pick_vs_sweep_variants_filtered.tsv
*SNPs only and whether they are present in pick, sweep, or both

excluding problematic SNPs*]

N --> |combine_and_mask_pick_and_sweep_vars_filt| P

L--> |count_variants| Q[variant_count.tsv]
P--> |count_variants_filt| R[variant_count_filtered.tsv]
R--> |snp_matrix| S[snp_matrix.tsv]
```


