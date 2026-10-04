# 01_data_load.R
# Load GiBleed OMOP CDM dataset using Eunomia and CDMConnector

library(CDMConnector)
library(dplyr)
library(dbplyr)
library(duckdb)

# Create a local DuckDB database with the GiBleed OMOP CDM dataset
# First run downloads the data into EUNOMIA_DATA_FOLDER; subsequent runs reuse the local copy
db_path <- eunomiaDir(
  datasetName = "GiBleed",
  cdmVersion = "5.3",
  databaseFile = tempfile(fileext = ".duckdb")
)

con <- DBI::dbConnect(duckdb::duckdb(dbdir = db_path))

# Create a cdm object for convenient dplyr-based access
cdm <- cdmFromCon(
  con = con,
  cdmSchema = "main",
  writeSchema = "main",
  cdmName = "GiBleed"
)

# Inspect the cdm object (list of OMOP tables)
print(cdm)

# Save connection and cdm object for subsequent scripts
saveRDS(list(con = con, cdm = cdm), file = "output/connection.rds")