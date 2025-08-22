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

## Assemblies

### *de novo* assemblies

Use the sanger PaM pipelines
https://ssg-confluence.internal.sanger.ac.uk/display/PaMI/Unicycler+%28short+reads%29+assembly+pipelinepipelines

```bash

module load assembly-unicycler-short-read
bsub -o output.o -e error.e -q oversubscribed -R "select[mem>4000] rusage[mem=4000]" -M4000 assembly-unicycler-short-read --manifest tracs_single_colony_wgs_manifest.csv --outdir asemblies


```

### Assembly QC with checkM

```bash

# Get all the assemblies
find assemblies/ -name "*assembly.fa" | grep unicycle > all_tracs_assemblies.txt

# run check m
checkm-as-jobarray-wrapper all_tracs_assemblies.txt checkm

# a few samples failed and needed 12G ram instead on 4

# collate all the files
find . -name "quality_report.tsv" | xargs cat | grep -v Name > checkm_summary.tsv



```

## Final QC

Use `R/sequencing_analysis/pull_wgs_ecoli_and_kleb.R` to make lists of E. coli
and Kleb lanes from manifest and qc files and upload to the farm for next steps

## prokka - annotation

Needs to be Genus specific - so prep list. 
```bash

# get e coli and kleb using the R script above on the all_tracs_assemblies.txt 

cat all_tracs_assemblies.txt | grep -f tracs_wgs_ecoli_assemblies.txt > tracs_ecoli_assemblies_filepath.txt
cat all_tracs_assemblies.txt | grep -f tracs_wgs_kleb_assemblies.txt > tracs_kleb_assemblies_filepath.txt

# run

prokka-as-jobarray-wrapper tracs_ecoli_assemblies_filepath.txt annotations Escherichia
prokka-as-jobarray-wrapper tracs_kleb_assemblies_filepath.txt annotations Klebsiella

```

## panaroo - core gene alignment

```bash

cat tracs_wgs_ecoli_assemblies.txt | sed 's/.assembly.fa/.gff/' > > tracs_wgs_ecoli_annotations.txt
find annotations/ -name *.gff | grep -f tracs_wgs_ecoli_annotations.txt > tracs_ecoli_annotations_filepath.txt


bsub -o pangenome/log.o -e pangenome/log.e -q normal -R "select[mem>20000] rusage[mem=20000]" -M20000 -n 6 -R "span[hosts=1]" "panaroo -i tracs_ecoli_annotations_filepath.txt -o pangenome --clean-mode strict -t 6 -a core"
```


```

