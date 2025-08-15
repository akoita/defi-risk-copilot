-- Token-centric features: holder concentration, LP adds/removes, volume z-score (last 30 days)
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.token_features`
PARTITION BY DATE(updated_at)
CLUSTER BY token_address AS
WITH xfers AS (
  SELECT
    LOWER(token_address) AS token_address,
    DATE(block_timestamp) AS d,
    COUNT(*) AS txs,
    APPROX_TOP_COUNT(LOWER(to_address), 10)[OFFSET(0)].count AS top1,
    (SELECT SUM(c) FROM UNNEST((
      SELECT ARRAY(SELECT cnt FROM UNNEST(t) cnt ORDER BY cnt DESC LIMIT 10)
      FROM (
        SELECT ARRAY(SELECT el.count FROM UNNEST(APPROX_TOP_COUNT(LOWER(to_address), 100)) el) t
      )
    ))) AS top100_sum,
    COUNT(DISTINCT LOWER(to_address)) AS holders
  FROM `bigquery-public-data.blockchain_analytics.ethereum_mainnet.token_transfers`
  WHERE _PARTITIONDATE BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
  GROUP BY token_address, d
), daily AS (
  SELECT token_address,
         SUM(txs) AS vol_30d,
         AVG(txs) AS vol_avg,
         STDDEV(txs) AS vol_std,
         ANY_VALUE(MAX(DATE(d))) AS last_day
  FROM xfers GROUP BY token_address
), lpev AS (
  SELECT
    LOWER(pool_address) AS pool_address,
    ANY_VALUE(LOWER(COALESCE(token0, ''))) AS token0,
    ANY_VALUE(LOWER(COALESCE(token1, ''))) AS token1,
    DATE(block_timestamp) AS d,
    SUM(CASE WHEN event_name = 'Mint' THEN SAFE_COALESCE(liq,0) ELSE 0 END) AS lp_added,
    SUM(CASE WHEN event_name = 'Burn' THEN SAFE_COALESCE(liq,0) ELSE 0 END) AS lp_removed
  FROM `${PROJECT_ID}.${DATASET}.pool_events`
  GROUP BY pool_address, d
), lps AS (
  SELECT
    COALESCE(token0, token1) AS token_address, -- heuristic fallback
    SUM(lp_added) AS lp_added_30d,
    SUM(lp_removed) AS lp_removed_30d
  FROM lpev
  GROUP BY token_address
)
SELECT
  LOWER(d.token_address) AS token_address,
  d.vol_30d AS vol_30d,
  d.vol_avg,
  d.vol_std,
  SAFE_DIVIDE(vol_30d - vol_avg, NULLIF(vol_std,0)) AS vol_z,
  SAFE_DIVIDE(top100_sum, NULLIF(SUM(holders) OVER (PARTITION BY d.token_address),0)) AS top100_share,
  COALESCE(l.lp_added_30d,0) AS lp_added_30d,
  COALESCE(l.lp_removed_30d,0) AS lp_removed_30d,
  CURRENT_TIMESTAMP() AS updated_at
FROM daily d
LEFT JOIN lps l ON l.token_address = d.token_address;
