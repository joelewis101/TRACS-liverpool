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
* Encrypt with gpg or your tool of choice. Change the
`token_fetch_string` string in `R/import_data_from_redcap.R` to be a system call to
return the token string.  
* run the `import_data_from_redcap.sh` script which will make a logfile of the
data download to go back to later and put everything in `data/raw`
