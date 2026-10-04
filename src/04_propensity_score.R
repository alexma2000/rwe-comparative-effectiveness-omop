# 04_propensity_score.R
# Propensity score estimation: P(celecoxib) ~ age + gender

library(dplyr)
library(ggplot2)

# Load cohort
cohort_final <- readRDS("output/cohort_final.rds")

# Prepare variables for PS model
cohort_ps <- cohort_final |>
  mutate(
    treat_celecoxib = ifelse(treatment == "celecoxib", 1, 0),
    gender_male = ifelse(gender_concept_id == 8507, 1, 0)
  )

# Logistic regression for propensity score
ps_model <- glm(
  treat_celecoxib ~ age_at_index + gender_male,
  data = as.data.frame(cohort_ps),
  family = binomial()
)

summary(ps_model)

# Predict PS (probability of receiving celecoxib)
cohort_ps <- cohort_ps |>
  mutate(
    ps = predict(ps_model, type = "response"),
    logit_ps = log(ps / (1 - ps))
  )

# PS distribution by treatment
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

ps_hist <- ggplot(cohort_ps, aes(x = ps, fill = treatment)) +
  geom_histogram(alpha = 0.5, position = "identity", bins = 30) +
  labs(
    title = "Propensity score distribution by treatment",
    x = "P(celecoxib)",
    y = "Count"
  ) +
  theme_minimal()

ggsave("output/figures/ps_distribution.png", ps_hist, width = 6, height = 4)

# Save cohort with PS
saveRDS(cohort_ps, file = "output/cohort_with_ps.rds")

# Quick check: mean PS by treatment
ps_summary <- cohort_ps |>
  group_by(treatment) |>
  summarise(
    n = n(),
    mean_ps = mean(ps),
    sd_ps = sd(ps),
    min_ps = min(ps),
    max_ps = max(ps)
  )

print(ps_summary)
