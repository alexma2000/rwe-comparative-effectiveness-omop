# Comparative Effectiveness Analysis of GI Bleeding Risk: NSAIDs vs Antiplatelets vs Anticoagulants

## Overview

This project performs a comparative effectiveness analysis of gastrointestinal (GI) bleeding risk associated with three major drug classes using OMOP CDM data:

- **NSAIDs** (Non-steroidal anti-inflammatory drugs)
- **Antiplatelets** (e.g., aspirin, clopidogrel)
- **Anticoagulants** (e.g., warfarin, heparin)

## Key Findings

| Drug Group | N Patients | GI Bleed Events | Incidence (per 1000 PY) | OR vs Anticoagulant (95% CI) |
|------------|------------|-----------------|-------------------------|-------------------------------|
| NSAID | 2,694 | 479 | 99.7 | 6.96 (3.16-19.69) |
| Antiplatelet | 1,976 | 332 | 84.2 | 6.5 (2.94-18.42) |
| Anticoagulant | 166 | 5 | 15.1 | Reference |

**Conclusion:** Both NSAIDs and antiplatelets are associated with significantly higher odds of GI bleeding compared to anticoagulants (OR ~6-7x).

## Project Structure

```
.
├── src/                       # R analysis scripts
│   ├── 01_data_load.R         # Database connection and CDM setup
│   ├── 02_cohort_definition.R # Define study cohorts
│   ├── 03_descriptives.R      # Baseline characteristics
│   ├── 04_propensity_score.R  # PS model estimation
│   ├── 05_matching_or_weighting.R # Matching/weighting
│   ├── 06_cohort_create.R     # Create final cohorts
│   ├── 07_analysis_summary.R  # Main analysis summary
│   └── 08_gi_bleed_analysis.R # GI bleeding outcome analysis
├── output/                    # Results and reports
│   ├── PROJECT_SUMMARY.md     # Executive summary
│   ├── gi_bleed_analysis_report.md
│   ├── gi_bleed_risk_summary_table.csv
│   ├── gi_bleed_odds_ratios.csv
│   ├── gi_bleed_risk_by_group.png
│   ├── cohort_exposure.csv
│   ├── drug_groups.csv
│   └── ...
├── README.md
└── .gitignore
```

## Analysis Pipeline

### Script 01: Data Load

- Establishes database connection (DuckDB)
- Loads OMOP CDM tables using CDMConnector
- Creates connection metadata

### Script 02: Cohort Definition

- Defines drug exposure cohorts
- Identifies NSAID, antiplatelet, and anticoagulant users
- Sets index dates (first prescription)

### Script 03: Descriptives

- Generates baseline characteristics
- Creates Table 1 (demographics, comorbidities)
- Produces descriptive statistics by treatment group

### Script 04: Propensity Score

- Estimates propensity scores
- Logistic regression model for treatment assignment
- Saves PS scores for matching/weighting

### Script 05: Matching or Weighting

- Performs propensity score matching or weighting
- Assesses balance (SMD plots)
- Creates matched/weighted cohorts

### Script 06: Cohort Create

- Finalizes study cohorts
- Applies inclusion/exclusion criteria
- Saves cohort data for analysis

### Script 07: Analysis Summary

- Main comparative effectiveness analysis
- Generates summary tables and figures
- Creates baseline balance tables

### Script 08: GI Bleed Analysis

- **Drug exposure analysis**: 113 unique drugs, 3 therapeutic groups
- **Cohort construction**: NSAID (2,694), Antiplatelet (1,976), Anticoagulant (166)
- **Outcome identification**: GI bleeding (SNOMED/ICD-10 codes)
- **Risk analysis**: Incidence rates per 1000 person-years
- **Comparative analysis**: Odds ratios with 95% CI

## Quick Start

```r
# Run full analysis pipeline
source("src/01_data_load.R")
source("src/02_cohort_definition.R")
source("src/03_descriptives.R")
source("src/04_propensity_score.R")
source("src/05_matching_or_weighting.R")
source("src/06_cohort_create.R")
source("src/07_analysis_summary.R")
source("src/08_gi_bleed_analysis.R")  # GI bleeding outcome
```

## Data Source

- **Database**: OMOP CDM v5.x (DuckDB)
- **Tables used**: `drug_exposure`, `concept`, `condition_occurrence`, `person`
- **Drug concepts**: 113 unique drugs across 3 therapeutic classes
- **Outcome**: GI bleeding (SNOMED: 192671, ICD-10: 35208414)

## Methods

### Cohort Definition

1. **Drug exposure cohorts**: Patients with ≥1 prescription for NSAID, antiplatelet, or anticoagulant
2. **Index date**: First drug exposure date
3. **Follow-up**: From index date to GI bleed event, 2 years, or end of data

### Outcome Definition

GI bleeding defined by:
- SNOMED: Gastrointestinal hemorrhage (192671)
- ICD-10-CM: Gastrointestinal hemorrhage, unspecified (35208414)

### Statistical Analysis

- Incidence rates per 1000 person-years
- Logistic regression for odds ratios
- Reference group: Anticoagulants

## Key Output Files

| File | Description |
|------|-------------|
| `output/PROJECT_SUMMARY.md` | Executive summary |
| `output/gi_bleed_analysis_report.md` | Full GI bleeding report |
| `output/gi_bleed_risk_summary_table.csv` | Incidence rates by drug group |
| `output/gi_bleed_odds_ratios.csv` | Odds ratios with 95% CI |
| `output/gi_bleed_risk_by_group.png` | Bar chart visualization |
| `output/cohort_exposure.csv` | Patient-level cohort data |
| `output/drug_groups.csv` | Drug classification |
| `output/tables/table1_baseline.txt` | Table 1 baseline characteristics |
| `output/figures/` | SMD plots, PS distribution, age by treatment |

## Installation

```r
# Required packages
install.packages(c(
  "CDMConnector",
  "DBI",
  "duckdb",
  "dplyr",
  "lubridate",
  "ggplot2",
  "broom"
))
```

## Limitations

- Observational data: residual confounding possible
- No dose-response analysis
- Limited follow-up (max 2 years)
- Single database (external validation needed)

## License

MIT License

## Citation

If you use this code, please cite:

```
@software{gibleed2026,
  author = {Alexander M.},
  title = {Comparative Effectiveness Analysis: GI Bleeding Risk with NSAIDs, Antiplatelets, and Anticoagulants},
  year = {2026},
  url = {https://github.com/alexma2000/rwe-comparative-effectiveness-omop}
}
```

