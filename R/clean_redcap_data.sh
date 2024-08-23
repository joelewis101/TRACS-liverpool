#!/bin/zsh

echo "Running clean_redcap_data.R"
echo "Logfile is at ../data/processed/clean_data_log$(date '+%Y%m%d-%H%M').txt"
RScript clean_redcap_data.R &> ../data/processed/clean_data_log$(date "+%Y%m%d-%H%M").txt
echo "done"
