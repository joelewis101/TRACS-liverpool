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

## Overview of pipeline


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
*all SNPs, filtered only for variant quaity ie QUAL decomposed and normalised with vt]
```

Reminder

* QUAL - measure of variant quality used by bcftools
* samtools -q is base quality, -Q is mapping quality
