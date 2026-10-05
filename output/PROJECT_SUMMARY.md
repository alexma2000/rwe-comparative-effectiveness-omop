# GiBleed Project - Analysis Complete ✅

## Analysis Pipeline Completed

1. **Drug Exposure Analysis**
   - 113 unique drug concepts identified
   - 3 therapeutic groups: NSAID (6 drugs), Antiplatelet (2), Anticoagulant (2)
   - Total drug exposures: 10,934

2. **Cohort Construction**
   - NSAID: 2,694 patients
   - Antiplatelet: 1,976 patients
   - Anticoagulant: 166 patients
   - Total: 4,836 patients

3. **GI Bleeding Outcome**
   - 2 ICD/SNOMED concepts identified
   - 479 unique patients with GI bleed (816 events)

4. **Risk Analysis**
   - Incidence rates calculated (per 1000 person-years)
   - NSAID: 99.7 (highest)
   - Antiplatelet: 84.2
   - Anticoagulant: 15.1 (lowest)

5. **Comparative Analysis**
   - Odds ratios vs Anticoagulant:
   - NSAID: OR = 6.96 (95% CI: 3.16-19.69)
   - Antiplatelet: OR = 6.5 (95% CI: 2.94-18.42)

## Key Deliverables

| File | Description |
|------|-------------|
| `gi_bleed_analysis_report.md` | Full analysis report |
| `gi_bleed_risk_summary_table.csv` | Summary statistics |
| `gi_bleed_odds_ratios.csv` | OR with 95% CI |
| `gi_bleed_risk_by_group.png` | Visualization |
| `cohort_exposure.csv` | Patient-level data |
| `drug_groups.csv` | Drug classification |

## Next Steps (Optional)

- Propensity score matching (already available: `cohort_with_ps.rds`)
- Time-to-event analysis (Cox regression)
- Subgroup analysis by age/sex/comorbidities
- Sensitivity analyses with different follow-up windows

