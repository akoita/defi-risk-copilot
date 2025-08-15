#!/usr/bin/env bash
set -euo pipefail

./scripts/bootstrap.sh

# Init
./scripts/run_sql.sh sql/00_init/01_create_dataset.sql
# 02 is notes/manual step for connection
./scripts/run_sql.sh sql/00_init/03_create_remote_models.sql

# Features
./scripts/run_sql.sh sql/10_features/11_pool_events.sql
./scripts/run_sql.sh sql/10_features/10_address_features.sql
./scripts/run_sql.sh sql/10_features/12_token_features.sql

# Models
./scripts/run_sql.sh sql/20_models/20_kmeans_addresses.sql
./scripts/run_sql.sh sql/20_models/21_arima_token_volume.sql
./scripts/run_sql.sh sql/20_models/22_detect_anomalies.sql

# Vectors
./scripts/run_sql.sh sql/30_vectors/30_contract_fingerprint.sql
./scripts/run_sql.sh sql/30_vectors/31_contract_embedding.sql
./scripts/run_sql.sh sql/30_vectors/32_vector_index.sql

# Explanations
./scripts/run_sql.sh sql/40_explanations/40_row_level_explanations.sql

# Views (final deliverables)
./scripts/run_sql.sh sql/50_views/50_address_alerts.sql
./scripts/run_sql.sh sql/50_views/51_token_alerts.sql
./scripts/run_sql.sh sql/50_views/52_similar_contracts.sql

echo "All done. Check views in ${PROJECT_ID}.${DATASET}"
