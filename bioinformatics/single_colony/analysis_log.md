# Analysis log

This document is a record of the basic single colony pick analysis on the Sanger
compute cluster. All my scripts that are used in this analysis are in the
`single_colony/scripts/` folder in this repo

## Download reads

### get study manifest from IRODS

See https://gitlab.internal.sanger.ac.uk/sanger-pathogens/pipelines/irods_extractor/-/wikis/home 

```bash

# get study manifest usijng TRACS study ID

# load PaM irods scripts
module load irods_extractor
iinit
# check logon expiry date if you want
/software/isg/scripts/iexpire

irods_extractor --studyid 7835 --search

```

### Pull out single colony pick samples

The manifest includes sweep and single colonies - use the script
`R/sequencing_analysis/collate_sequence_metadata.R` to save a manifest in the
format that `irods_extractor` - a csv file with headings 

| studyid | runid | laneid | plexid |
------------------------------------

### Download fastqs

```bash

irods_extractor --manifest_of_lanes tracs_single_colony_wgs_manifest.csv

```

## Read QC

### Trim with fastp

Use a couple of scripts to submit as a job array to the farm - make sure the
scripts are in somewhere on `$PATH`

```bash

module load fastp
fastp-as-jobarray-wrapper outdir
# check how many successful completions
 ls | grep o$ | xargs -I '{}'  grep  Success '{}' | wc -l
 # should be same as number of samples

# summarise fastp results
s *.json | xargs -I % jq -r '[.command, .summary.before_filtering.total_reads, .summary.after_filtering.total_reads  ] | @tsv' % > json_summary.tsv
```

Bring locally and plot with `R/sequencing_analysis/plot_read_qc.R`

### Kraken/braken

```bash
# remember to load bracken and kraken modules
kraken-as-jobarray-wrapper /data/pam/software/kraken2/standard_08gb_20250402/k2_standard_08gb_20250402 kraken
cd kraken
bracken-as-jobarray-wrapper /data/pam/software/kraken2/standard_08gb_20250402/k2_standard_08gb_20250402 kraken
bracken_summarise bracken_summary.tsv


```

## *de novo* assemblies

Use the sanger PaM pipelines
https://ssg-confluence.internal.sanger.ac.uk/display/PaMI/Unicycler+%28short+reads%29+assembly+pipelinepipelines

```bash

module load assembly-unicycler-short-read
bsub -o output.o -e error.e -q oversubscribed -R "select[mem>4000] rusage[mem=4000]" -M4000 assembly-unicycler-short-read --manifest tracs_single_colony_wgs_manifest.csv --outdir asemblies


```
