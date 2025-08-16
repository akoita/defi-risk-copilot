# DeFi Risk Copilot – Starter Repo

A production-ready, **SQL-first** starter kit to build a BigQuery AI risk & explainability engine for DeFi (rug-pull + wash-trading) with **BQML**, **Gemini in BigQuery (remote models)**, and **Vector Search**.

> **Location note**: Create the BigQuery dataset in **US** multi-region to query `bigquery-public-data` without cross-region errors.

## What problem this solves

- **Fragmented, hard-to-explain DeFi risk signals**: Rug-pulls, wash trading and coordinated drains are difficult to detect quickly and explain to stakeholders.
- **Heavy lift to stand up infra**: Many teams need weeks to build data pipelines, ML, and dashboards. This repo provides a ready-to-run, BigQuery-native pipeline.
- **Need for explainability**: Risk teams and PMs need short, defensible explanations tied to concrete on-chain features.

## How it works (at a glance)

- **SQL-first in BigQuery**: End-to-end ELT written in SQL; no separate services to operate.
- **Features**: Aggregates decoded on-chain events to compute signals per address and token (e.g., `vol_z` for volume anomalies, `top100_share` for holder concentration, `lp_removed_30d` for liquidity pulls).
- **Models (BQML)**: K-Means clustering for address behavior; ARIMA for token volume anomalies; lightweight rules for initial risk flags.
- **Vector search**: Contract fingerprinting + embeddings to find similar contracts for context and triage.
- **Explanations (Gemini in BigQuery)**: Row-level, natural-language rationales generated directly in SQL using remote models.
- **Deliverables**: Final views you can query or wire to BI:
  - `${PROJECT_ID}.${DATASET}.address_alerts`
  - `${PROJECT_ID}.${DATASET}.token_alerts`
  - `${PROJECT_ID}.${DATASET}.similar_contracts`
- **Optional dashboard**: One-page Looker Studio spec in `dash/` to visualize alerts, trends, and similarities.

## Quickstart
1. `cp .env.sample .env` and fill values.
2. `bash scripts/run_all.sh`
3. Explore final views:
   - `${PROJECT_ID}.${DATASET}.address_alerts`
   - `${PROJECT_ID}.${DATASET}.token_alerts`
   - `${PROJECT_ID}.${DATASET}.similar_contracts`

## Cost Guardrails
- All source queries limited to last **30 days** via `_PARTITIONDATE`.
- Tables partitioned by date and clustered by address/token.
- Keep vector index on a compact table. Consider filtering to **top active contracts** if needed.

## Stretch
- Add chains (Polygon/Arbitrum/Optimism) using the same decoded events schema.
- Replace simple rules with a learned classifier (XGBoost) using weak labels (LP drain heuristics).
