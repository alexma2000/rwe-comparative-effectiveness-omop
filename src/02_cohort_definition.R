# 02_cohort_definition.R
# Define new-user cohorts of diclofenac vs celecoxib in GiBleed

library(CDMConnector)
library(dplyr)

# Load saved connection
obj <- readRDS("output/connection.rds")
con <- obj$con
cdm <- obj$cdm

# PERSON: basic patient information
person <- cdm$person

# DRUG_EXPOSURE: drug prescriptions/dispensing
drug <- cdm$drug_exposure

# CONDITION_OCCURRENCE: diagnoses (for future exclusion / baseline covariates)
condition <- cdm$condition_occurrence

# In GiBleed, diclofenac and celecoxib are already represented by specific concept_ids.
# For this educational example, we use fixed concept_ids.
# In a real project, these would be identified via vocabulary searches or ATLAS.

diclofenac_concept_id <- 1125315  # example, to be verified in the specific dataset
celecoxib_concept_id  <- 1118084  # example, to be verified in the specific dataset

# New users: first drug exposure per patient
drug_first <- drug |>
  group_by(person_id) |>
  arrange(drug_exposure_start_date) |>
  slice(1) |>
  ungroup()

# Diclofenac cohort
cohort_diclo <- drug_first |>
  filter(drug_concept_id == diclofenac_concept_id) |>
  select(person_id, index_date = drug_exposure_start_date, treatment = "diclofenac")

# Celecoxib cohort
cohort_celeb <- drug_first |>
  filter(drug_concept_id == celecoxib_concept_id) |>
  select(person_id, index_date = drug_exposure_start_date, treatment = "celecoxib")

# Combine cohorts
cohort <- bind_rows(cohort_diclo, cohort_celeb)

# Add demographics from person table
cohort_wide <- cohort |>
  left_join(person |> select(person_id, gender_concept_id, year_of_birth), by = "person_id") |>
  mutate(
    age_at_index = 2026 - year_of_birth  # simplified, ignores month/day
  )

# Restrict to adults (>= 18 years)
cohort_final <- cohort_wide |>
  filter(age_at_index >= 18) |>
  select(person_id, index_date, treatment, gender_concept_id, age_at_index)

# Save intermediate cohort file
saveRDS(cohort_final, file = "output/cohort_final.rds")

# Quick summary check by treatment
cohort_final |>
  group_by(treatment) |>
  summarise(
    n = n(),
    mean_age = mean(age_at_index, na.rm = TRUE),
    prop_male = mean(gender_concept_id == 8507, na.rm = TRUE)
  )
