-- Address anomalies (ML-based): distance to KMeans centroid with z-score threshold
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.address_anomalies` AS
WITH preds AS (
  SELECT
    p.address,
    p.tx_count,
    p.unique_peers,
    p.pct_internal_calls,
    p.reuse_ratio,
    p.centroid_id AS cluster_id,
    p.nearest_centroids_distance[OFFSET(0)].distance AS dist
  FROM ML.PREDICT(
    MODEL `${PROJECT_ID}.${DATASET}.kmeans_addresses`,
    (
      SELECT
        address,
        CAST(tx_count AS FLOAT64) AS tx_count,
        CAST(unique_peers AS FLOAT64) AS unique_peers,
        LOG(1 + CAST(COALESCE(mean_value, 0) AS FLOAT64)) AS mean_value_log1p,
        CAST(COALESCE(pct_internal_calls, 0) AS FLOAT64) AS pct_internal_calls,
        CAST(COALESCE(reuse_ratio, 0) AS FLOAT64) AS reuse_ratio
      FROM `${PROJECT_ID}.${DATASET}.address_features`
    )
  ) AS p
), stats AS (
  SELECT AVG(dist) AS mean_dist, STDDEV(dist) AS std_dist FROM preds
)
SELECT
  preds.*,
  SAFE_DIVIDE(preds.dist - stats.mean_dist, NULLIF(stats.std_dist, 0)) AS dist_z,
  (SAFE_DIVIDE(preds.dist - stats.mean_dist, NULLIF(stats.std_dist, 0)) > 3) AS is_anomaly
FROM preds
CROSS JOIN stats;

-- Optional: forecast and compute residual spikes for tokens
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.token_forecast` AS
SELECT *
FROM ML.FORECAST(MODEL `${PROJECT_ID}.${DATASET}.arima_token_volume`, STRUCT(7 AS horizon, 0.8 AS confidence_level));

-- Residual-spike anomalies: compare actual daily txs vs forecast interval
-- Flags rows where actuals fall outside the prediction interval
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.token_residual_anomalies` AS
WITH actuals AS (
  SELECT
    LOWER(token_address) AS token_address,
    DATE(block_timestamp) AS forecast_timestamp,
    COUNT(*) AS actual_txs
  FROM `${TOKEN_TRANSFERS_TABLE}`
  WHERE DATE(block_timestamp) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY) AND CURRENT_DATE()
  GROUP BY token_address, forecast_timestamp
), joined AS (
  SELECT
    f.token_address,
    f.forecast_timestamp,
    f.forecast_value,
    f.prediction_interval_lower_bound AS lower_bound,
    f.prediction_interval_upper_bound AS upper_bound,
    a.actual_txs,
    CASE WHEN a.actual_txs < f.prediction_interval_lower_bound OR a.actual_txs > f.prediction_interval_upper_bound THEN TRUE ELSE FALSE END AS is_anomaly
  FROM `${PROJECT_ID}.${DATASET}.token_forecast` f
  JOIN actuals a
    ON f.token_address = a.token_address
   AND DATE(f.forecast_timestamp) = a.forecast_timestamp
)
SELECT *
FROM joined
WHERE is_anomaly = TRUE;
