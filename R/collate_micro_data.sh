#!/bin/zsh

echo "Running collate_micro_data.R"
echo "Logfile is at ../data/processed/micro_extract_log$(date '+%Y%m%d-%H%M').txt"
RScript collate_micro_data.R &> ../data/processed/micro_extract_log$(date "+%Y%m%d-%H%M").txt
echo "done"
