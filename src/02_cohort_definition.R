# 02_cohort_definition.R
# Define new-user cohorts of diclofenac vs celecoxib in GiBleed
# New user = first exposure to this specific drug per patient

library(CDMConnector)
library(dplyr)
library(dbplyr)
library(duckdb)

# Load connection metadata
meta <- readRDS("output/connection_meta.rds")
db_path <- meta$db_path

# Recreate fresh connection in this session
con <- DBI::dbConnect(duckdb::duckdb(dbdir = db_path))

cdm <- cdmFromCon(
  con = con,
  cdmSchema = "main",
  writeSchema = "main",
  cdmName = meta$cdm_name
)

# PERSON: basic patient information
person <- cdm$person

# DRUG_EXPOSURE: drug prescriptions/dispensing
drug <- cdm$drug_exposure

# CONDITION_OCCURRENCE: diagnoses (for future exclusion / baseline covariates)
condition <- cdm$condition_occurrence

# Concept IDs for drugs of interest
diclofenac_concept_id <- 1124300  # Diclofenac (RxNorm)
celecoxib_concept_id  <- 1118084  # celecoxib (RxNorm)

# Diclofenac new users: first diclofenac exposure per patient
cohort_diclo <- drug |>
  filter(drug_concept_id == diclofenac_concept_id) |>
  group_by(person_id) |>
  arrange(person_id, drug_exposure_start_date) |>
  mutate(row_id = row_number()) |>
  filter(row_id == 1) |>
  ungroup() |>
  select(-row_id) |>
  select(person_id, index_date = drug_exposure_start_date) |>
  mutate(treatment = "diclofenac") |>
  collect()

# Celecoxib new users: first celecoxib exposure per patient
cohort_celeb <- drug |>
  filter(drug_concept_id == celecoxib_concept_id) |>
  group_by(person_id) |>
  arrange(person_id, drug_exposure_start_date) |>
  mutate(row_id = row_number()) |>
  filter(row_id == 1) |>
  ungroup() |>
  select(-row_id) |>
  select(person_id, index_date = drug_exposure_start_date) |>
  mutate(treatment = "celecoxib") |>
  collect()

# Combine cohorts
cohort <- bind_rows(cohort_diclo, cohort_celeb)

# Add demographics from person table
cohort_wide <- cohort |>
  left_join(person |> select(person_id, gender_concept_id, year_of_birth) |> collect(), by = "person_id") |>
  mutate(
    age_at_index = 2026 - year_of_birth  # simplified, ignores month/day
  )

# Restrict to adults (>= 18 years)
cohort_final <- cohort_wide |>
  filter(age_at_index >= 18) |>
  select(person_id, index_date, treatment, gender_concept_id, age_at_index)

# Collect into memory and save
cohort_final_local <- cohort_final |> collect()

saveRDS(cohort_final_local, file = "output/cohort_final.rds")

# Quick summary check by treatment
summary_table <- cohort_final_local |>
  group_by(treatment) |>
  summarise(
    n = n(),
    mean_age = mean(age_at_index, na.rm = TRUE),
    prop_male = mean(gender_concept_id == 8507, na.rm = TRUE)
  )

print(summary_table)