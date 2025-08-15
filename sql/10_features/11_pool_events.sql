-- Derive normalized AMM pool events (UniswapV2/V3-like) from decoded events
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.pool_events`
PARTITION BY DATE(block_timestamp)
CLUSTER BY pool_address AS
WITH ev AS (
  SELECT
    LOWER(e.contract_address) AS pool_address,
    e.event_name,
    e.block_timestamp,
    e.tx_hash,
    -- token0/token1 if available (depends on ABI decode quality)
    ANY_VALUE(CASE WHEN e.event_name IN ('Swap','Mint','Burn') THEN e.params['token0'] END) AS token0,
    ANY_VALUE(CASE WHEN e.event_name IN ('Swap','Mint','Burn') THEN e.params['token1'] END) AS token1,
    -- Liquidity delta approximation (fallback to 0 if not present)
    SAFE_CAST(e.params['liquidity'] AS FLOAT64) AS liq,
    SAFE_CAST(e.params['amount0'] AS FLOAT64) AS amount0,
    SAFE_CAST(e.params['amount1'] AS FLOAT64) AS amount1
  FROM `bigquery-public-data.blockchain_analytics.ethereum_mainnet.decoded_events` e
  WHERE _PARTITIONDATE BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
    AND e.event_name IN ('Swap','Mint','Burn')
)
SELECT * FROM ev;
