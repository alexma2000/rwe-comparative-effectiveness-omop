# GI Bleeding Risk Analysis by Drug Group

## Cohort Characteristics

Total patients: 4836
Total GI bleeding events: 816

## Incidence Rates

| Drug Group | N Patients | N Events | Follow-up (years) | Incidence (per 1000 PY) | Incidence (%) |
|------------|------------|----------|-------------------|-------------------------|---------------|
| NSAID | 2694 | 479 | 4806 | 99.66 | 17.78 |
| Antiplatelet | 1976 | 332 | 3944 | 84.18 | 16.8 |
| Anticoagulant | 166 | 5 | 332 | 15.06 | 3.01 |

## Odds Ratios (Reference: Anticoagulant)

| Comparison | OR | 95% CI |
|------------|-----|---------|
| Antiplatelet | 6.5 | 2.94-18.42 |
| NSAID | 6.96 | 3.16-19.69 |

## Key Findings

- **NSAID**: Highest incidence rate (99.7 per 1000 PY), 17.8% of patients experienced GI bleed
- **Antiplatelet**: 84.2 per 1000 PY, 16.8% event rate
- **Anticoagulant**: Lowest incidence (15.1 per 1000 PY), 3.0% event rate
- **Odds ratios**: Both NSAID (OR=6.96) and Antiplatelet (OR=6.5) show significantly higher odds of GI bleeding compared to Anticoagulant

## Files Generated

- `output/gi_bleed_risk_summary_table.csv` - Summary statistics
- `output/gi_bleed_odds_ratios.csv` - Odds ratios with 95% CI
- `output/gi_bleed_risk_by_group.png` - Bar chart visualization
- `output/cohort_exposure.csv` - Patient-level cohort data
- `output/gi_bleeding_events.csv` - GI bleeding events

