#!/bin/bash

# Define the root directory to search
SEARCH_DIR="/Users/sarah.gallichan/Documents/Pipe_test/TRACS-liverpool/bioinformatics/snakemake"

# Output header
echo -e "Folder Name\tFull Path"

# Find all "data" directories and format the output
find "$SEARCH_DIR" -type d -name "data" | while read dir; do
    echo -e "$(basename "$dir")\t$dir"
done