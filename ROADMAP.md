# Polymarket Analytics — Roadmap

> How accurate are Polymarket's prices, and can the gaps be traded?

A daily pipeline that pulls Polymarket data into SQL Server, then tests how well prices predict outcomes, which factors matter, and whether a simple strategy would have made money.

## Stack

Python (pandas, NumPy) · SQL Server · Airflow · Power BI · Excel · Docker · Git

## Pipeline

```
Polymarket APIs → raw JSON → stg → core (star schema) → mart → Power BI · Excel
```

## Phase 1 — Data pipeline *(weekend 1)*

- [ ] SQL Server running in Docker Compose
- [ ] Python client for the Gamma and CLOB APIs
- [ ] Load raw → stg → core, safe to re-run
- [ ] Data-quality checks

## Phase 2 — Analysis *(weekend 2)*

- [ ] Calibration: does a 20¢ price really mean a 20% chance?
- [ ] Factors: price level, momentum, volatility, time to close
- [ ] Backtest the longshot strategy, with trading costs and no look-ahead
- [ ] Save results to mart tables

## Phase 3 — Reporting & automation *(weekend 3)*

- [ ] Power BI dashboard
- [ ] Automated Excel report
- [ ] Daily Airflow run
- [ ] README with findings and methodology

## Later *(optional)*

- [ ] Live screener in Streamlit, online

## Not in scope

Kafka, Spark, machine-learning models.
