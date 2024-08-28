#!/bin/zsh

echo "Running import_data_from_redcap.R"
echo "Logfile is at ../data/raw/redcap_extract_log$(date '+%Y%m%d-%H%M').txt"
RScript import_data_from_redcap.R &> ../data/raw/redcap_extract_log$(date "+%Y%m%d-%H%M").txt
retval=$?
if [ $retval -ne 0 ]
then
  echo "Failed with exit code " $retval " - check logs"
else
  echo "Completed, exit code" $retval
fi
