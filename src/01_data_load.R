# 01_data_load.R
# Load GiBleed OMOP CDM dataset and save connection metadata

library(CDMConnector)
library(dplyr)
library(dbplyr)
library(duckdb)

# Create a local DuckDB database with the GiBleed OMOP CDM dataset
db_path <- eunomiaDir(
  datasetName = "GiBleed",
  cdmVersion = "5.3",
  databaseFile = tempfile(fileext = ".duckdb")
)

con <- DBI::dbConnect(duckdb::duckdb(dbdir = db_path))

cdm <- cdmFromCon(
  con = con,
  cdmSchema = "main",
  writeSchema = "main",
  cdmName = "GiBleed"
)

# Inspect the cdm object (list of OMOP tables)
print(cdm)

# Save only metadata, not the live connection
saveRDS(
  list(
    db_path = db_path,
    cdm_name = "GiBleed",
    cdm_version = "5.3"
  ),
  file = "output/connection_meta.rds"
)