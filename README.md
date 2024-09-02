# TRACS-liverpool

Data cleaning and analysis for the TRACS-Liverpool study


## Repo structure

Scripts go in the `R/` folder
Data and api tokens to access database do in `data/` - these are not pushed to
the repo.

```
├── R
│   ├── clean_data.R
│   ├── import_data_from_redcap.R
│   └── import_data_from_redcap.sh
├── README.md
└── data
    ├── processed
    ├── raw
    └── secrets
        └── redcap_token.txt.gpg
```

## Downloading data from redcap

* request an API token.   
* Encrypt with gpg or your tool of choice. Friends don't let friends leave plain
text access tokens lying around. Change the `token_fetch_string` string in
`R/import_data_from_redcap.R` to be a terminal call to return the token string.
* Either:
  + run the import_data_from_redcap.R script which will download all the
  instruments from redcap and put them in their own csv file in `data/raw` *or*
  + run the `import_data_from_redcap.sh` script which will do that but pipe the
  console output to a logfile (`redcap_extract_logYYMMDD-HHMM.txt` and put it in
  `data/raw`.

## Cleaning up

See the file `data_structure.md` for a description of what the data clean script
does to the redcap data. Either run it directly or run
`clean_redcap_data.sh` which will save a logfile in `data/processed`

## Downloading micro data

See `data_structure.md` for a description of the way the micro data is stored
and the structure of the data extractions. Raw data is on the LSTM shared drive.
The `collate_micro_data.R` script will download it if the drive is mounted (on a
mac) and the `download_data` flag in the script is `TRUE`.

The following scripts will collate the micro results and environmental location
data respectively:

* `R/collate_micro_data.R` will save the micro results in
`data/processed/micro_processedYYMMDD_HHMM` and will also output some data
queries. The shell wrapper script will save its output as a logfile.
* `R/collate_env_loc_data.R` will save the location data in
`data/processed/micro_env_sample_locYYYYMMDD-HHMM.csv` - shell wrapper script
saves logfile.
