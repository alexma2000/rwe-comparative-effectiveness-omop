# 08_gi_bleed_analysis.R
# GI Bleeding Risk Analysis by Drug Group

library(CDMConnector)
library(DBI)
library(dplyr)
library(lubridate)
library(ggplot2)
library(broom)

# ============================================
# 1. Load drug groups
# ============================================

drug_groups <- read.csv("output/drug_groups.csv", stringsAsFactors = FALSE) |>
  mutate(concept_id = as.integer(concept_id))

cat("Drug groups loaded:", nrow(drug_groups), "drugs\n")

# ============================================
# 2. Get drug exposure data
# ============================================

drug_exposure_local <- cdm$drug_exposure |>
  collect() |>
  mutate(drug_concept_id = as.integer(drug_concept_id))

cat("Drug exposure records:", nrow(drug_exposure_local), "\n")

# ============================================
# 3. Count exposures by drug group
# ============================================

exposure_by_group <- drug_exposure_local |>
  inner_join(
    drug_groups |>
      select(
        drug_concept_id = concept_id,
        drug_group,
        concept_name
      ),
    by = "drug_concept_id"
  ) |>
  count(drug_group, concept_name, sort = TRUE)

write.csv(exposure_by_group, "output/exposure_by_drug_group.csv", row.names = FALSE)

# Summary by group
group_summary <- exposure_by_group |>
  group_by(drug_group) |>
  summarise(
    total_exposures = sum(n),
    n_drugs = n(),
    .groups = "drop"
  ) |>
  arrange(desc(total_exposures))

write.csv(group_summary, "output/drug_group_summary.csv", row.names = FALSE)
print(group_summary)

# ============================================
# 4. Create cohort with index dates
# ============================================

exposures <- drug_exposure_local |>
  inner_join(
    drug_groups |>
      select(
        drug_concept_id = concept_id,
        drug_group,
        concept_name
      ),
    by = "drug_concept_id"
  )

# First exposure per person per group
cohort_exposure <- exposures |>
  group_by(person_id, drug_group) |>
  summarise(
    index_date = min(drug_exposure_start_date),
    n_exposures = n(),
    .groups = "drop"
  )

write.csv(cohort_exposure, "output/cohort_exposure.csv", row.names = FALSE)

cat("\nCohort summary:\n")
print(
  cohort_exposure |>
    group_by(drug_group) |>
    summarise(
      n_patients = n_distinct(person_id),
      total_exposures = sum(n_exposures),
      .groups = "drop"
    )
)

# ============================================
# 5. Identify GI bleeding outcomes
# ============================================

# GI bleeding concept IDs
gi_bleed_ids <- c(35208414, 192671)

# Get all GI bleeding occurrences
gi_bleeding <- cdm$condition_occurrence |>
  filter(condition_concept_id %in% gi_bleed_ids) |>
  collect() |>
  mutate(
    condition_start_date = as.Date(condition_start_date),
    person_id = as.integer(person_id)
  )

cat("\nGI bleeding events:", nrow(gi_bleeding), "\n")
cat("Unique patients:", n_distinct(gi_bleeding$person_id), "\n")

write.csv(gi_bleeding, "output/gi_bleeding_events.csv", row.names = FALSE)

# ============================================
# 6. Calculate incidence rates
# ============================================

# Get first GI bleed per patient
first_bleed <- gi_bleeding |>
  group_by(person_id) |>
  summarise(first_bleed_date = min(condition_start_date), .groups = "drop")

# Join cohort with outcomes
cohort_with_outcome <- cohort_exposure |>
  left_join(first_bleed, by = "person_id") |>
  mutate(
    index_date = as.Date(index_date),
    has_gi_bleed = !is.na(first_bleed_date) & first_bleed_date >= index_date,
    censor_date = as.Date("2026-10-05"),
    max_followup = index_date + years(2),
    effective_bleed_date = ifelse(has_gi_bleed, first_bleed_date, NA),
    end_followup = as.Date(
      ifelse(
        has_gi_bleed,
        pmin(as.character(first_bleed_date), as.character(max_followup), as.character(censor_date)),
        as.character(pmin(max_followup, censor_date))
      )
    ),
    follow_up_days = as.numeric(end_followup - index_date),
    follow_up_years = follow_up_days / 365.25
  )

# Summary by drug group
risk_by_group <- cohort_with_outcome |>
  group_by(drug_group) |>
  summarise(
    n_patients = n(),
    n_events = sum(has_gi_bleed, na.rm = TRUE),
    total_followup_years = sum(follow_up_years, na.rm = TRUE),
    incidence_rate_per_1000py = round(1000 * n_events / total_followup_years, 2),
    incidence_proportion_pct = round(100 * n_events / n_patients, 2),
    .groups = "drop"
  ) |>
  arrange(desc(incidence_rate_per_1000py))

print("\n=== GI BLEEDING RISK BY DRUG GROUP ===")
print(risk_by_group)

write.csv(risk_by_group, "output/gi_bleed_risk_by_group.csv", row.names = FALSE)

# ============================================
# 7. Calculate odds ratios
# ============================================

cohort_analysis <- cohort_with_outcome |>
  mutate(
    drug_group = factor(drug_group, levels = c("Anticoagulant", "Antiplatelet", "NSAID"))
  )

# Logistic regression: Anticoagulant as reference
model <- glm(
  has_gi_bleed ~ relevel(drug_group, ref = "Anticoagulant"),
  data = cohort_analysis,
  family = binomial()
)

# Get odds ratios - simplified version
or_results <- broom::tidy(model, exponentiate = TRUE, conf.int = TRUE) |>
  filter(term != "(Intercept)") |>
  select(
    Comparison = term,
    OR = estimate,
    OR_lower = conf.low,
    OR_upper = conf.high
  ) |>
  mutate(
    OR = round(OR, 2),
    OR_lower = round(OR_lower, 2),
    OR_upper = round(OR_upper, 2)
  )

print("\n=== ODDS RATIOS (Reference: Anticoagulant) ===")
print(or_results)

write.csv(or_results, "output/gi_bleed_odds_ratios.csv", row.names = FALSE)

# ============================================
# 8. Create visualization
# ============================================

risk_by_group$drug_group <- factor(
  risk_by_group$drug_group,
  levels = c("Anticoagulant", "Antiplatelet", "NSAID")
)

p <- ggplot(risk_by_group, aes(x = drug_group, y = incidence_rate_per_1000py, fill = drug_group)) +
  geom_col(width = 0.6) +
  geom_text(
    aes(label = paste0(incidence_rate_per_1000py, " per 1000 PY (n=", n_events, ")")),
    vjust = -0.5,
    size = 5
  ) +
  labs(
    title = "GI Bleeding Incidence Rate by Drug Group",
    subtitle = "Events per 1000 person-years",
    x = "Drug Group",
    y = "Incidence Rate (per 1000 PY)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14),
    axis.text.x = element_text(size = 11)
  )

ggsave("output/gi_bleed_risk_by_group.png", p, width = 8, height = 5, dpi = 150)
cat("\nPlot saved to output/gi_bleed_risk_by_group.png\n")

# ============================================
# 9. Create summary table
# ============================================

summary_table <- risk_by_group |>
  select(
    Drug_Group = drug_group,
    N_Patients = n_patients,
    N_Events = n_events,
    FollowUp_Years = total_followup_years,
    Incidence_per_1000PY = incidence_rate_per_1000py,
    Incidence_Proportion_pct = incidence_proportion_pct
  ) |>
  mutate(FollowUp_Years = round(FollowUp_Years, 0))

write.csv(summary_table, "output/gi_bleed_risk_summary_table.csv", row.names = FALSE)

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Results saved to output/gi_bleed_*.csv\n")

