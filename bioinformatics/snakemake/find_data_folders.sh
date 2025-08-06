#!/bin/bash

find . -type d -name "data" -maxdepth 4 | while read -r data_path; do
parent_dir=$(dirname "$data_path")

snakemake --config reads="$data_path" output="$parent_dir/out" -R --rerun-incomplete
done
