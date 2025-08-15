-- Basic behavioral features for addresses (last 30 days)
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.address_features`
PARTITION BY DATE(updated_at)
CLUSTER BY address AS
WITH txs AS (
  SELECT
    LOWER(from_address) AS address,
    COUNT(*) AS tx_count,
    COUNT(DISTINCT to_address) AS unique_peers,
    AVG(value) AS mean_value,
    SAFE_DIVIDE(
      COUNTIF(from_address = to_address),
      COUNT(*)
    ) AS reuse_ratio,
    TIMESTAMP_TRUNC(MAX(block_timestamp), DAY) AS updated_at
  FROM `bigquery-public-data.blockchain_analytics.ethereum_mainnet.transactions`
  WHERE _PARTITIONDATE BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
  GROUP BY address
), internals AS (
  SELECT LOWER(from_address) AS address,
         SAFE_DIVIDE(SUM(CASE WHEN call_type = 'call' THEN 1 ELSE 0 END), COUNT(*)) AS pct_internal_calls
  FROM `bigquery-public-data.blockchain_analytics.ethereum_mainnet.traces`
  WHERE _PARTITIONDATE BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
  GROUP BY address
)
SELECT
  t.address,
  t.tx_count,
  t.unique_peers,
  t.mean_value,
  COALESCE(i.pct_internal_calls, 0) AS pct_internal_calls,
  t.reuse_ratio,
  -- toy behavior vector (expand later)
  [CAST(t.tx_count AS FLOAT64),
   CAST(t.unique_peers AS FLOAT64),
   1000*COALESCE(i.pct_internal_calls, 0),
   1000*COALESCE(t.reuse_ratio,0)
  ] AS behavior_vec,
  t.updated_at
FROM txs t
LEFT JOIN internals i USING(address);
