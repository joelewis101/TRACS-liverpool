# Aims of this repo

Lots of code going back and forth to get the TRACS snakemake repo up and running
- this can serve as a place to develop the pipeline.

## Structure

Snakefiles are in `snakemake/` directory. Data to test the pipeline should go in
the `snakemake/data` folder - data files aren't pushed to github as very big. A
README in the snakmake directory details how to run the pipeline.

## Setting up the environment

Tested on my macbook M3 pro

### Install snakemake

Needs to be on osx-64 platform (if on mac) because of availability of snippy on
bioconda

`conda create -c conda-forge -c bioconda --platform osx-64 -n snakemake_TRACS snakemake-minimal`
`conda activate snakemake_TRACS`

### Install snippy

The homebrew install of snippy fails because of a dependency on openssl1.1
which is now deprecated. The conda installation as of 28 Jan 2025 works, but the
environment needs to be os-64. Also I needed to install a C++ library needed by
bcftools (otherwise you get a `you have bcftools version 0` error

`conda install bioconda::snippy`
`conda install conda-forge::gsl`

### Clone repo

`git@github.com:joelewis101/TRACS-liverpool.git`

## Traps for the unwary 

* Samtools 1.21 breaks the snippy workflow - see:

[https://github.com/tseemann/snippy/issues/598]
[https://github.com/bioconda/bioconda-recipes/pull/51628]

The workaround is to roll back to <= 1.20 - the bioconda dependencies should do
this automatically

* Error messgae: can't locate Bio/SeqIO

This is a perl library problem. Make sure BioPerl is installed (`brew install
bioperl`) then add the library location to the perl library variable

`export PERL5LIB=/opt/homebrew/Cellar/bioperl/1.7.8_2/libexec/lib/perl5/:$PERL5LIB`

* snippy error `you have bcftools version 0` following conda install

Needs the gsl C++ library - see above



