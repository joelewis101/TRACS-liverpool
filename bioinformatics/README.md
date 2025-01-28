# Setting up the environment

Tested on my macbook M3 pro

## Installing snippy

The homebrew install of snippy fails because of a dependency on openssl1.1
which is now deprecated. The conda installation as of 28 Jan 2025 works, but the
environment needs to be os-64. 

Make a new environment with

`conda create --name snippy --platform osx-64 --channel bioconda`

Activate and install - I also needed to install a C++ library for bcftools

`conda activate bioconda::snippy`
`conda install conda-forge::gsl`

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



