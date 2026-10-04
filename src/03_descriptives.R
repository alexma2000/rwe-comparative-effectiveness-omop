# 03_descriptives.R
# Baseline descriptives for diclofenac vs celecoxib cohorts

install.packages("tableone")

library(dplyr)
library(tableone)
library(ggplot2)

# Load cohort
cohort_final <- readRDS("output/cohort_final.rds")

# Convert to factors for tableone
cohort_final <- cohort_final |>
  mutate(
    gender = factor(
      ifelse(gender_concept_id == 8507, "Male", "Female"),
      levels = c("Male", "Female")
    ),
    treatment = factor(treatment, levels = c("diclofenac", "celecoxib"))
  )

# Variables for Table 1
vars_for_table <- c("age_at_index", "gender")

# Create Table 1 stratified by treatment
table_one <- CreateTableOne(
  vars = vars_for_table,
  strata = "treatment",
  data = as.data.frame(cohort_final),
  test = FALSE  # no significance tests for now
)

print(table_one, smd = TRUE)  # smd = standardized mean differences

# Save Table 1 as text
dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)
capture.output(print(table_one, smd = TRUE), file = "output/tables/table1_baseline.txt")

# Age distribution by treatment
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

age_plot <- ggplot(cohort_final, aes(x = treatment, y = age_at_index, fill = treatment)) +
  geom_boxplot(alpha = 0.7) +
  labs(
    title = "Age distribution by treatment",
    x = "Treatment",
    y = "Age at index date"
  ) +
  theme_minimal()

ggsave("output/figures/age_by_treatment.png", age_plot, width = 6, height = 4)

# Gender distribution
gender_table <- cohort_final |>
  group_by(treatment, gender) |>
  summarise(n = n(), .groups = "drop") |>
  group_by(treatment) |>
  mutate(prop = n / sum(n))

print(gender_table)
