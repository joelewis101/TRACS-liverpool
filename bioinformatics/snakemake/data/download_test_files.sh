#!/bin/bash

echo "Downloading test files ..."

wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR342/006/ERR3425926/ERR3425926_1.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR342/006/ERR3425926/ERR3425926_2.fastq.gz
wget  "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=U00096.3&rettype=fasta" -O U00096.3.fasta

