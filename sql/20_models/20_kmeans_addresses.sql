-- Train KMeans on address behavior
CREATE OR REPLACE MODEL `${PROJECT_ID}.${DATASET}.kmeans_addresses`
OPTIONS (
  model_type = 'KMEANS',
  num_clusters = 12,
  max_iterations = 20,
  standardize_features = TRUE,
  kmeans_init_method = 'KMEANS_PLUS_PLUS'
) AS
SELECT
  CAST(tx_count AS FLOAT64) AS tx_count,
  CAST(unique_peers AS FLOAT64) AS unique_peers,
  -- reduce scale; transactions.value can be very large (wei)
  LOG(1 + CAST(COALESCE(mean_value, 0) AS FLOAT64)) AS mean_value_log1p,
  CAST(COALESCE(pct_internal_calls, 0) AS FLOAT64) AS pct_internal_calls,
  CAST(COALESCE(reuse_ratio, 0) AS FLOAT64) AS reuse_ratio
FROM `${PROJECT_ID}.${DATASET}.address_features`
WHERE MOD(ABS(FARM_FINGERPRINT(address)), 10) = 0;
