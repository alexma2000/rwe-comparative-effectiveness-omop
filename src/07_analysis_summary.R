# 07_analysis_summary.R
# Save cohort analysis results

library(CDMConnector)
library(DBI)
library(dplyr)

# Load metadata and create database connection
meta <- readRDS("output/connection_meta.rds")
con <- dbConnect(duckdb::duckdb(dbdir = meta$db_path))

# ============================================================
# 1. Cohort summary
# ============================================================

cohort_summary <- dbGetQuery(con, "
  SELECT 
    COUNT(*) AS total_patients,
    MIN(cohort_start_date) AS first_event_date,
    MAX(cohort_start_date) AS last_event_date
  FROM gi_bleed_cohort
")

print("=== Cohort Summary ===")
print(cohort_summary)

# ============================================================
# 2. Age distribution
# ============================================================

age_distribution <- dbGetQuery(con, "
  SELECT 
    FLOOR(EXTRACT(YEAR FROM c.cohort_start_date) - p.year_of_birth) AS age_group,
    COUNT(*) AS n_patients
  FROM gi_bleed_cohort c
  JOIN person p ON c.subject_id = p.person_id
  GROUP BY age_group
  ORDER BY age_group
")

print("=== Age Distribution ===")
print(age_distribution)

# ============================================================
# 3. Comorbidities (top 15)
# ============================================================

comorbidities <- dbGetQuery(con, "
  SELECT 
    cnt.concept_name,
    cnt.vocabulary_id,
    COUNT(DISTINCT gc.subject_id) AS n_patients,
    COUNT(*) AS n_events
  FROM gi_bleed_cohort gc
  JOIN condition_occurrence c ON gc.subject_id = c.person_id
  JOIN concept cnt ON c.condition_concept_id = cnt.concept_id
  WHERE c.condition_concept_id != 192671  -- exclude GI bleeding itself
  GROUP BY cnt.concept_name, cnt.vocabulary_id
  ORDER BY n_patients DESC
  LIMIT 15
")

print("=== Comorbidities (Top 15) ===")
print(comorbidities)

# ============================================================
# 4. Yearly distribution
# ============================================================

yearly_distribution <- dbGetQuery(con, "
  SELECT 
    EXTRACT(YEAR FROM cohort_start_date) AS year,
    COUNT(*) AS n_patients
  FROM gi_bleed_cohort
  GROUP BY year
  ORDER BY year
")

print("=== Yearly Distribution ===")
print(yearly_distribution)

# ============================================================
# 5. Save results to CSV
# ============================================================

write.csv(cohort_summary, "output/cohort_summary.csv", row.names = FALSE)
write.csv(age_distribution, "output/age_distribution.csv", row.names = FALSE)
write.csv(comorbidities, "output/comorbidities.csv", row.names = FALSE)
write.csv(yearly_distribution, "output/yearly_distribution.csv", row.names = FALSE)

print("=== Results saved to output/ ===")

# Close connection
dbDisconnect(con)
