-- Train KMeans on address behavior
CREATE OR REPLACE MODEL `${PROJECT_ID}.${DATASET}.kmeans_addresses`
OPTIONS (
  model_type = 'KMEANS',
  num_clusters = 20
) AS
SELECT tx_count, unique_peers, mean_value, pct_internal_calls, reuse_ratio
FROM `${PROJECT_ID}.${DATASET}.address_features`;
