-- Final view: suspicious addresses (join features + anomaly score)
CREATE OR REPLACE VIEW `${PROJECT_ID}.${DATASET}.address_alerts` AS
SELECT
  f.address,
  f.tx_count,
  f.unique_peers,
  f.mean_value,
  f.pct_internal_calls,
  a.is_anomaly,
  a.anomaly_score,
  f.updated_at
FROM `${PROJECT_ID}.${DATASET}.address_features` f
JOIN `${PROJECT_ID}.${DATASET}.address_anomalies` a USING(address);
