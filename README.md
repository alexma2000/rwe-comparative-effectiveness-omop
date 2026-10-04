# RWE Comparative Effectiveness Study (OMOP-like data)

## Research question

Сравнить риск [primary outcome] у новых пользователей Treatment A и Treatment B в течение [follow-up] на OMOP-подобных данных.

## Design

- Тип дизайна: retrospective active-comparator, new-user cohort study.
- Data source: OMOP-like учебный набор (публичные данные, не для клинических выводов).
- Population: взрослые пациенты, впервые начавшие Treatment A или B.
- Index date: дата первого назначения препарата.
- Baseline period: 365 дней до index date.
- Outcome: [например, госпитализация по причине X].
- Confounding control: propensity score (логистическая регрессия) + matching/IPTW.
- Analysis: time-to-event (Cox model) или risk ratio, в зависимости от данных.

## Structure

- `src/01_data_load.R` — загрузка и базовая проверка данных.
- `src/02_cohort_definition.R` — определение когорт, index date, inclusion/exclusion.
- `src/03_descriptives.R` — описательная статистика по когортам.
- `src/04_propensity_score.R` — модель PS, covariates.
- `src/05_matching_or_weighting.R` — matching или IPTW, проверка баланса.
- `src/06_outcome_analysis.R` — outcome model.
- `src/07_tables_figures.R` — таблицы и графики.

## How to run

1. Установить зависимости: `install.packages(c("dplyr", "survival", "tableone", ...))`.
2. Запустить скрипты по порядку: `01_... → 07_...`.
3. Результаты — в папке `output/`.

## Limitations

- Учебные данные, не репрезентативны для реальной популяции.
- Упрощённые definitions exposure/outcome.
- Проект создан для демонстрации RWE-pipeline, а не для клинических выводов.

## Author

[Твоё имя / GitHub username]