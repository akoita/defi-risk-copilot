# DeFi Risk Copilot – Starter Repo

A production-ready, **SQL-first** starter kit to build a BigQuery AI risk & explainability engine for DeFi (rug-pull + wash-trading) with **BQML**, **Gemini in BigQuery (remote models)**, and **Vector Search**.

> **Location note**: Create the BigQuery dataset in **US** multi-region to query `bigquery-public-data` without cross-region errors.

## Project Objective
- Showcase Google Cloud’s native ML features end-to-end on public on-chain data:
  - **BigQuery ML**: clustering (KMeans), time-series forecasting (ARIMA_PLUS), anomaly scoring.
  - **BigQuery remote models (Vertex AI)**: text generation with Gemini 2.5 Flash and text embeddings.
  - **BigQuery Vector Search**: vector index and nearest neighbor queries for similar contracts.
  - **BI**: optional Looker Studio page for alerts and explanations.
- Zero servers: everything orchestrated by SQL in BigQuery.

## What problem this solves

- **Fragmented, hard-to-explain DeFi risk signals**: Rug-pulls, wash trading and coordinated drains are difficult to detect quickly and explain to stakeholders.
- **Heavy lift to stand up infra**: Many teams need weeks to build data pipelines, ML, and dashboards. This repo provides a ready-to-run, BigQuery-native pipeline.
- **Need for explainability**: Risk teams and PMs need short, defensible explanations tied to concrete on-chain features.

## How it works (at a glance)

- **SQL-first in BigQuery**: End-to-end ELT written in SQL; no separate services to operate.
- **Features**: Aggregates on-chain events to compute signals per address and token (e.g., `vol_z` for volume anomalies, `top100_share` for holder concentration, `lp_removed_7d` for liquidity pulls). Defaults to logs-based AMM extraction from `bigquery-public-data.crypto_ethereum.logs`.
- **Models (BQML)**: K-Means clustering for address behavior; ARIMA for token volume anomalies; lightweight rules for initial risk flags.
- **Vector search**: Contract fingerprinting + embeddings to find similar contracts for context and triage. Performance-optimized with scope limiting for large datasets.
- **Explanations (Gemini in BigQuery)**: Row-level, natural-language rationales generated directly in SQL using remote models.
- **Deliverables**: Final views you can query or wire to BI:
  - `${PROJECT_ID}.${DATASET}.address_alerts`
  - `${PROJECT_ID}.${DATASET}.token_alerts`
  - `${PROJECT_ID}.${DATASET}.similar_contracts`
- **Optional dashboard**: One-page Looker Studio spec in `dash/` to visualize alerts, trends, and similarities.

## Hackathon Alignment
- Built for the Kaggle “BigQuery AI Hackathon”: emphasizes native BigQuery ML, remote models via Vertex AI, and vector search. Swap in additional models or chains as needed to fit challenge rules and scoring.

## Quickstart
1. Copy env and fill values:
   - `cp .env.sample .env`
   - Required vars:
     - `PROJECT_ID`: your GCP project (e.g., `my-project`)
     - `DATASET`: BigQuery dataset name (default `risk_copilot`)
     - `BQ_LOCATION`: BigQuery location (default `US`)
     - `CONNECTION_NAME`: BigQuery connection for Vertex AI (e.g., `US.vertex_us`)
2. Create a BigQuery connection for Vertex AI (one-time):
   - Console: BigQuery > Connections > +Create Connection > Type: Cloud resource > Location: `US` > Name: `vertex_us`
   - Or CLI: `bq mk --location=US --connection --display_name=vertex_us --connection_type=CLOUD_RESOURCE vertex_us`
   - Grant the connection service account:
     - Vertex AI User (`roles/aiplatform.user`)
     - BigQuery Job User (`roles/bigquery.jobUser`)
     - Optional: BigQuery Data Viewer (`roles/bigquery.dataViewer`)
3. Run the pipeline: `bash scripts/run_all.sh`
   - If remote models fail, ensure Gemini is enabled in us-central1 and the connection SA has Vertex AI User + BigQuery Job User.
   - If KMeans intermittently fails with a transient BigQuery error, rerun or use the built-in sampling in `sql/20_models/20_kmeans_addresses.sql`.
4. Explore final views:
### Optional automation for a new GCP project
- Instead of doing step 2 manually, you can auto-bootstrap APIs and the connection:
  - Set `AUTO_BOOTSTRAP_GCP=true` in `.env`, then run `bash scripts/run_all.sh`, or
  - Run directly: `bash scripts/bootstrap_gcp.sh`
- The script enables APIs (BigQuery, BigQuery Connection, Vertex AI, IAM, Cloud Resource Manager), creates the connection (e.g., `US.vertex_us`) and grants roles (`roles/aiplatform.user`, `roles/bigquery.jobUser`) to the connection service account.

   - `${PROJECT_ID}.${DATASET}.address_alerts`
   - `${PROJECT_ID}.${DATASET}.token_alerts`
   - `${PROJECT_ID}.${DATASET}.similar_contracts`

## Cost Guardrails
- Source queries now default to last **7 days** (reduced scope) via DATE filters.
- Tables partitioned by date and clustered by address/token.
- Explanations are incremental and capped per run (top 100 highest-risk; 128 max tokens) to respect quotas.
- Keep vector index on a compact table. Consider filtering to **top active contracts** if needed.

## Performance Considerations
- **Vector Search Performance**: The `similar_contracts` view is optimized for performance by limiting scope to 1000 contracts by default. Without this limit, queries on large datasets (300K+ contracts) can take hours due to cross-product comparisons.
- **Vector Index Requirements**: Ensure the vector index `vx_contract_embedding` is fully built before running VECTOR_SEARCH queries. Check status via `INFORMATION_SCHEMA.VECTOR_INDEXES`.
- **Query Optimization**: For production use, adjust the `LIMIT` in the view based on your performance requirements:
  - `LIMIT 1000`: ~5M comparisons, completes in ~25 seconds
  - `LIMIT 5000`: ~25M comparisons, moderate performance
  - `LIMIT 10000`: ~100M comparisons, slower performance
- **Contract Fingerprinting**: Uses `LOGS_TABLE` (not `DECODED_EVENTS_TABLE`) with topic0 hashes as event surrogates for compatibility with public BigQuery datasets.

## Troubleshooting
- **"Table contract_embedding was not found"**: Ensure you've run the vector pipeline steps in order: `30_contract_fingerprint.sql` → `31_contract_embedding.sql` → `32_vector_index.sql` → `52_similar_contracts.sql`
- **Vector Search queries taking hours**: Check that the vector index is ACTIVE in `INFORMATION_SCHEMA.VECTOR_INDEXES`. If queries are still slow, the view may need scope limiting (see Performance Considerations above).
- **"Index type is required"**: Ensure `32_vector_index.sql` includes `index_type = 'IVF'` option.
- **"Column embed must have same array length"**: The embedding model outputs 768-dimensional vectors. Filter to consistent lengths if needed.

## Dashboard (Looker Studio)
- Create BigQuery data sources for:
  - `${PROJECT_ID}.${DATASET}.token_alerts` (columns include `token_address`, `vol_7d`, `vol_z`, `top100_share`, `lp_removed_7d`, `explanation`, `updated_at`)
  - `${PROJECT_ID}.${DATASET}.address_alerts`
  - `${PROJECT_ID}.${DATASET}.similar_contracts` (optional)
- Token Alerts page suggestions:
  - Table sorted by `vol_z` desc; filters for `vol_z`, `top100_share`, and `lp_removed_7d > 0`.
  - Conditional colors for `vol_z` and `top100_share`.
  - Custom field: Etherscan link via `CONCAT('https://etherscan.io/token/', token_address)`.
- Address Alerts page: table with `dist_z`, `is_anomaly` and filters.
- Similar Contracts page: table with neighbor distances and link-outs.

## Stretch
## Public Data Mapping
- Logs: `bigquery-public-data.crypto_ethereum.logs`
- Token transfers: `bigquery-public-data.crypto_ethereum.token_transfers`
- Transactions: `bigquery-public-data.crypto_ethereum.transactions`
- Traces: `bigquery-public-data.crypto_ethereum.traces`

Set these in `.env` as `LOGS_TABLE`, `TOKEN_TRANSFERS_TABLE`, `TRANSACTIONS_TABLE`, `TRACES_TABLE`. The SQL templates read them via env substitution. **Note**: The vector pipeline uses `LOGS_TABLE` for contract fingerprinting (not `DECODED_EVENTS_TABLE`).

- Add chains (Polygon/Arbitrum/Optimism) using the same logs/decoded events schema.
- Replace simple rules with a learned classifier (XGBoost) using weak labels (LP drain heuristics).
