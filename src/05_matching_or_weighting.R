# 05_matching_or_weighting.R
# Propensity score matching and balance diagnostics

#install.packages("MatchIt")

library(dplyr)
library(MatchIt)
library(tableone)
library(ggplot2)
library(tidyr)

# Load cohort with PS
cohort_ps <- readRDS("output/cohort_with_ps.rds")

# Convert treatment to numeric (0 = diclofenac, 1 = celecoxib)
cohort_ps <- cohort_ps |>
  mutate(
    treat_num = ifelse(treatment == "celecoxib", 1, 0)
  )

# 1:1 nearest neighbor matching with caliper = 0.2 * SD(logit PS)
match_out <- matchit(
  treat_num ~ age_at_index + gender_concept_id,
  data = as.data.frame(cohort_ps),
  method = "nearest",
  ratio = 1,
  caliper = 0.2 * sd(cohort_ps$logit_ps, na.rm = TRUE)
)

summary(match_out)  # balance diagnostics before/after matching

# Extract matched dataset
matched_data <- match.data(match_out)

# Check sample size after matching
cat("Original sample size:", nrow(cohort_ps), "\n")
cat("Matched sample size:", nrow(matched_data), "\n")

# Table 1 before matching
table_one_unmatched <- CreateTableOne(
  vars = c("age_at_index", "gender_concept_id"),
  strata = "treatment",
  data = as.data.frame(cohort_ps),
  test = FALSE
)

cat("\n--- Table 1: UNMATCHED ---\n")
print(table_one_unmatched, smd = TRUE)

# Table 1 after matching
table_one_matched <- CreateTableOne(
  vars = c("age_at_index", "gender_concept_id"),
  strata = "treatment",
  data = as.data.frame(matched_data),
  test = FALSE
)

cat("\n--- Table 1: MATCHED ---\n")
print(table_one_matched, smd = TRUE)

# Save matched cohort
saveRDS(matched_data, file = "output/matched_data.rds")

# Manual SMD calculation for plotting
# Function to compute SMD
smd_fun <- function(x, treat) {
  m1 <- mean(x[treat == 1], na.rm = TRUE)
  m0 <- mean(x[treat == 0], na.rm = TRUE)
  s1 <- sd(x[treat == 1], na.rm = TRUE)
  s0 <- sd(x[treat == 0], na.rm = TRUE)
  s_pooled <- sqrt((s1^2 + s0^2) / 2)
  (m1 - m0) / s_pooled
}

# Unmatched SMD
treat_unmatched <- ifelse(cohort_ps$treatment == "celecoxib", 1, 0)
smd_age_unmatched <- smd_fun(cohort_ps$age_at_index, treat_unmatched)
smd_gender_unmatched <- smd_fun(cohort_ps$gender_concept_id, treat_unmatched)

# Matched SMD
treat_matched <- ifelse(matched_data$treatment == "celecoxib", 1, 0)
smd_age_matched <- smd_fun(matched_data$age_at_index, treat_matched)
smd_gender_matched <- smd_fun(matched_data$gender_concept_id, treat_matched)

# Data frame for plotting
smd_df <- data.frame(
  variable = c("age_at_index", "age_at_index", "gender_concept_id", "gender_concept_id"),
  smd = c(smd_age_unmatched, smd_age_matched, smd_gender_unmatched, smd_gender_matched),
  stage = factor(c("Unmatched", "Matched", "Unmatched", "Matched"),
                 levels = c("Unmatched", "Matched"))
)

# Plot SMD before and after matching
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

smd_plot <- ggplot(smd_df, aes(x = variable, y = abs(smd), fill = stage)) +
  geom_col(position = "dodge", alpha = 0.7) +
  geom_hline(yintercept = 0.1, linetype = "dashed", color = "red") +
  labs(
    title = "Absolute Standardized Mean Differences (SMD) before and after matching",
    x = "Variable",
    y = "Absolute SMD",
    fill = "Stage"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("output/figures/smd_comparison.png", smd_plot, width = 8, height = 5)

# Print SMD values
cat("\n--- SMD values ---\n")
cat("Age: unmatched =", round(smd_age_unmatched, 4), ", matched =", round(smd_age_matched, 4), "\n")
cat("Gender: unmatched =", round(smd_gender_unmatched, 4), ", matched =", round(smd_gender_matched, 4), "\n")