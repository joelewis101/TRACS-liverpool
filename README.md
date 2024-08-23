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
* Encrypt with gpg or your tool of choice. Friends don't friends leave plain
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
does. Either run it directly or run `clean_redcap_data.sh`which will save a
logfile in `data/processed`
