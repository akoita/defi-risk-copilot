-- Logs-based extraction using bigquery-public-data.crypto_ethereum.logs
-- NOTE: This version derives pools from factory events and captures Swap events.
--       Mint/Burn liquidity amounts are not decoded from logs and will be NULL.
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.pool_events`
PARTITION BY DATE(block_timestamp)
CLUSTER BY pool_address AS
WITH
  -- Helper to convert a 32-byte topic (or data word) to an EVM address string
  -- The input should be a 64-hex char word without the leading '0x'
  -- Address is the rightmost 40 hex chars
  v2_pairs AS (
    -- Uniswap V2 and SushiSwap V2 PairCreated events
    SELECT DISTINCT
      LOWER('0x' || SUBSTR(SUBSTR(l.topics[SAFE_OFFSET(1)], 3), 25, 40)) AS token0,
      LOWER('0x' || SUBSTR(SUBSTR(l.topics[SAFE_OFFSET(2)], 3), 25, 40)) AS token1,
      LOWER('0x' || SUBSTR(SUBSTR(SUBSTR(l.data, 3), 1, 64), 25, 40)) AS pool_address
    FROM `${LOGS_TABLE}` l
    WHERE DATE(l.block_timestamp) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
      AND LOWER(l.address) IN (
        '0x5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6', -- Uniswap V2 Factory
        '0xc0aee478e3658e2610c5f7a4a2e1777ce9e4f2ac'  -- SushiSwap V2 Factory
      )
      AND l.topics[SAFE_OFFSET(0)] = '0x0d3648bd0f6ba80134a33ba9275ac585d9d315f0ad8355cddefde31afa28d0e9' -- PairCreated
  ), v3_pools AS (
    -- Uniswap V3 PoolCreated events
    SELECT DISTINCT
      LOWER('0x' || SUBSTR(SUBSTR(l.topics[SAFE_OFFSET(1)], 3), 25, 40)) AS token0,
      LOWER('0x' || SUBSTR(SUBSTR(l.topics[SAFE_OFFSET(2)], 3), 25, 40)) AS token1,
      LOWER('0x' || SUBSTR(SUBSTR(SUBSTR(l.data, 3), 64*2 + 1, 64), 25, 40)) AS pool_address
    FROM `${LOGS_TABLE}` l
    WHERE DATE(l.block_timestamp) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
      AND LOWER(l.address) = '0x1f98431c8ad98523631ae4a59f267346ea31f984' -- Uniswap V3 Factory
      AND l.topics[SAFE_OFFSET(0)] = '0x783cca1c0412dd0d695e784568c93f8e1e1c9db8f9bf9c3f0106d06d5d9c8e5f' -- PoolCreated
  ), pools AS (
    SELECT pool_address, token0, token1 FROM v2_pairs
    UNION ALL
    SELECT pool_address, token0, token1 FROM v3_pools
  )
SELECT
  p.pool_address,
  'Swap' AS event_name,
  l.block_timestamp,
  l.transaction_hash AS tx_hash,
  p.token0,
  p.token1,
  CAST(NULL AS FLOAT64) AS liq,
  CAST(NULL AS FLOAT64) AS amount0,
  CAST(NULL AS FLOAT64) AS amount1
FROM `${LOGS_TABLE}` l
JOIN pools p ON LOWER(l.address) = p.pool_address
WHERE DATE(l.block_timestamp) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND CURRENT_DATE()
  AND l.topics[SAFE_OFFSET(0)] IN (
    -- Uniswap V2 Swap
    '0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822'
    -- Uniswap V3 Swap (best-effort; include if available)
    --,'0xc42079a0b...'
  );
