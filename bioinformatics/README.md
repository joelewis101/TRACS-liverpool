# Aims of this repo

A home for the bioinformatics scripts for TRACS, using snakemake.

## Structure

### Single colonies

Description of the analysis of single colony picks is in the `single_colony/`
folder.

### Analysis of MSWEEP/MGEMS bins

This is the wrapped in a snakemake pipeline.

Snakefiles are in `snakemake/` directory. Data to test the pipeline should go in
the `snakemake/data` folder - data files aren't pushed to github as very big. A
README in the snakmake directory details how to run the pipeline.

## dependencies

* snakemake
* snippy
* R 
  + dplyr
  + readr
  + stringr
  + tidyr
  + purrr
  + zoo
  + phylotools

## Setting up the environment

Tested on my macbook M3 pro

### Make conda env and activate

Needs to be on osx-64 platform (if on mac) because of availability of snippy on
bioconda - see below:

`conda create --platform osx-64 -n snakemake`  
`conda activate snakemake_TRACS`

### Install snippy

The homebrew install of snippy fails because of a dependency on openssl1.1
which is now deprecated. The conda installation as of 28 Jan 2025 works, but the
environment needs to be osx-64. Also I needed to install a C++ library needed by
bcftools (otherwise you get a `you have bcftools version 0` error

Install snippy **before** snakemake or I get an error (see below)

`conda install bioconda::snippy`  
`conda install conda-forge::gsl`

### Install snakemake

`conda install snakemake-minimal`

### R installation

Needs a R installation with the above packages

### Clone repo

`git@github.com:joelewis101/TRACS-liverpool.git`

## Traps for the unwary 

#### Samtools 1.21 breaks the snippy workflow - see:

[https://github.com/tseemann/snippy/issues/598]  
[https://github.com/bioconda/bioconda-recipes/pull/51628]  

The workaround is to roll back to <= 1.20 - the bioconda dependencies should do
this automatically

#### Error messgae: `can't locate Bio/SeqIO`

This is a perl library problem. Make sure BioPerl is installed (eg. `brew install
bioperl`) then add the library location to the perl library variable

`export PERL5LIB=/opt/homebrew/Cellar/bioperl/1.7.8_2/libexec/lib/perl5/:$PERL5LIB`

#### snippy error `you have bcftools version 0` following conda install

bcftools failing and hence not returning a version number - needs the gsl C++ library - see above

#### `pulp.apis.core.PulpSolverError: Pulp: Error while trying to execute, use msg=True for more detailscbc`

Some dependency problem - see

[https://github.com/snakemake/snakemake/issues/3128]  

fixed on my machine by installing snippy then snakemake, not the other way round


