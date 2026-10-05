# 06_cohort_create.R
# Create GI bleeding cohort

library(CDMConnector)
library(dplyr)
library(DBI)

# Load metadata and create database connection
meta <- readRDS("output/connection_meta.rds")
con <- dbConnect(duckdb::duckdb(dbdir = meta$db_path))

cdm <- cdmFromCon(
  con = con,
  cdmSchema = "main",
  writeSchema = "main",
  cdmName = meta$cdm_name
)

# Reference to OMOP tables
condition <- cdm$condition_occurrence
concept <- cdm$concept

# Find GI bleeding concepts
gi_bleed_concepts <- condition |>
  left_join(concept |> select(concept_id, concept_name, concept_code, vocabulary_id),
            by = c("condition_concept_id" = "concept_id")) |>
  filter(grepl("gastrointestinal|GI|bleed|hemorrhage", tolower(concept_name))) |>
  select(condition_concept_id, concept_name, concept_code, vocabulary_id) |>
  distinct() |>
  collect()

print("GI bleeding concepts:")
print(gi_bleed_concepts)

# Save concept IDs
gi_bleed_condition_ids <- gi_bleed_concepts$condition_concept_id
print(paste("Concept IDs:", paste(gi_bleed_condition_ids, collapse = ", ")))

# Drop existing cohort table if exists
dbExecute(con, "DROP TABLE IF EXISTS gi_bleed_cohort")

# Create cohort table
dbExecute(con, "
  CREATE TABLE gi_bleed_cohort (
    subject_id BIGINT,
    cohort_definition_id INTEGER,
    cohort_start_date DATE,
    cohort_end_date DATE
  )
")

# Insert cohort entries (patients 18+ years old, with 6-month washout period)
dbExecute(con, paste0("
  INSERT INTO gi_bleed_cohort
  SELECT DISTINCT
    c.person_id AS subject_id,
    1 AS cohort_definition_id,
    c.condition_start_date AS cohort_start_date,
    c.condition_end_date AS cohort_end_date
  FROM condition_occurrence c
  JOIN person p ON c.person_id = p.person_id
  JOIN observation_period op ON c.person_id = op.person_id
  WHERE c.condition_concept_id IN (", 
                      paste(gi_bleed_condition_ids, collapse = ", "), 
                      ")
  AND (EXTRACT(YEAR FROM c.condition_start_date) - p.year_of_birth) >= 18
  -- Washout period: at least 6 months of observation before the event
  AND op.observation_period_start_date <= c.condition_start_date - INTERVAL '6 months'
"))

# Verification: count patients
result <- dbGetQuery(con, "SELECT COUNT(*) AS n_patients FROM gi_bleed_cohort")
print(paste("Created cohort with", result$n_patients, "patients (18+, 6-month washout)"))

# Verification: check age range
age_check <- dbGetQuery(con, "
  SELECT 
    MIN(EXTRACT(YEAR FROM c.cohort_start_date) - p.year_of_birth) AS min_age,
    MAX(EXTRACT(YEAR FROM c.cohort_start_date) - p.year_of_birth) AS max_age
  FROM gi_bleed_cohort c
  JOIN person p ON c.subject_id = p.person_id
")
print(paste("Age range:", age_check$min_age, "-", age_check$max_age, "years"))

# Close connection
dbDisconnect(con)

#Check then
# library(CDMConnector)
# library(DBI)
# meta <- readRDS("output/connection_meta.rds")
# con <- dbConnect(duckdb::duckdb(dbdir = meta$db_path))
# dbGetQuery(con, "SELECT * FROM gi_bleed_cohort LIMIT 10")
# dbGetQuery(con, "SELECT COUNT(*) AS n FROM gi_bleed_cohort")
