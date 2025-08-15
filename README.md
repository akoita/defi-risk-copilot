# DeFi Risk Copilot – Starter Repo

A production-ready, **SQL-first** starter kit to build a BigQuery AI risk & explainability engine for DeFi (rug-pull + wash-trading) with **BQML**, **Gemini in BigQuery (remote models)**, and **Vector Search**.

> **Location note**: Create the BigQuery dataset in **US** multi-region to query `bigquery-public-data` without cross-region errors.

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
