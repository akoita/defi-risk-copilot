-- Token-centric features: holder concentration, LP adds/removes, volume z-score (last 7 days)
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.token_features`
PARTITION BY DATE(updated_at)
CLUSTER BY token_address AS
WITH per_rcpt AS (
  SELECT
    LOWER(token_address) AS token_address,
    DATE(block_timestamp) AS d,
    LOWER(to_address) AS to_addr,
    COUNT(*) AS c
  FROM `${TOKEN_TRANSFERS_TABLE}`
  WHERE DATE(block_timestamp) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND CURRENT_DATE()
  GROUP BY token_address, d, to_addr
), xfers AS (
  SELECT
    token_address,
    d,
    SUM(c) AS txs,
    COUNT(DISTINCT to_addr) AS holders
  FROM per_rcpt
  GROUP BY token_address, d
), topk AS (
  SELECT token_address, d, SUM(c) AS top100_sum
  FROM (
    SELECT
      token_address,
      d,
      c,
      ROW_NUMBER() OVER (PARTITION BY token_address, d ORDER BY c DESC) AS rn
    FROM per_rcpt
  )
  WHERE rn <= 100
  GROUP BY token_address, d
), daily AS (
  SELECT token_address,
         SUM(txs) AS vol_7d,
         AVG(txs) AS vol_avg,
         STDDEV(txs) AS vol_std,
         MAX(d) AS last_day
  FROM xfers GROUP BY token_address
), lpev AS (
  SELECT
    LOWER(pool_address) AS pool_address,
    ANY_VALUE(LOWER(COALESCE(token0, ''))) AS token0,
    ANY_VALUE(LOWER(COALESCE(token1, ''))) AS token1,
    DATE(block_timestamp) AS d,
    SUM(CASE WHEN event_name = 'Mint' THEN COALESCE(liq,0) ELSE 0 END) AS lp_added,
    SUM(CASE WHEN event_name = 'Burn' THEN COALESCE(liq,0) ELSE 0 END) AS lp_removed
  FROM `${PROJECT_ID}.${DATASET}.pool_events`
  GROUP BY pool_address, d
), lps AS (
  SELECT
    COALESCE(token0, token1) AS token_address, -- heuristic fallback
    SUM(lp_added) AS lp_added_7d,
    SUM(lp_removed) AS lp_removed_7d
  FROM lpev
  GROUP BY token_address
)
SELECT
  LOWER(d.token_address) AS token_address,
  d.vol_7d AS vol_7d,
  d.vol_avg,
  d.vol_std,
  SAFE_DIVIDE(vol_7d - vol_avg, NULLIF(vol_std,0)) AS vol_z,
  SAFE_DIVIDE(COALESCE(t.top100_sum,0), NULLIF(h.total_holders,0)) AS top100_share,
  COALESCE(l.lp_added_7d,0) AS lp_added_7d,
  COALESCE(l.lp_removed_7d,0) AS lp_removed_7d,
  CURRENT_TIMESTAMP() AS updated_at
FROM daily d
LEFT JOIN (
  SELECT token_address, SUM(top100_sum) AS top100_sum
  FROM topk
  GROUP BY token_address
) t ON t.token_address = d.token_address
LEFT JOIN (
  SELECT token_address, SUM(holders) AS total_holders
  FROM xfers
  GROUP BY token_address
) h ON h.token_address = d.token_address
LEFT JOIN lps l ON l.token_address = d.token_address;
