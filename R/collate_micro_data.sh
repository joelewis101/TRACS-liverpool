#!/bin/zsh

echo "Running collate_micro_data.R"
echo "Logfile is at ../data/processed/micro_extract_log$(date '+%Y%m%d-%H%M').txt"
RScript collate_micro_data.R &> ../data/processed/micro_extract_log$(date "+%Y%m%d-%H%M").txt
retval=$?
if [ $retval -ne 0 ]
then
  echo "Failed with exit code " $retval " - check logs"
else
  echo "Completed, exit code" $retval
fi
