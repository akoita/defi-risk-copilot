-- Time-series model per token for tx volume using ARIMA_PLUS
CREATE OR REPLACE MODEL `${PROJECT_ID}.${DATASET}.arima_token_volume`
OPTIONS (
  model_type = 'ARIMA_PLUS',
  time_series_timestamp_col = 'd',
  time_series_data_col = 'txs',
  time_series_id_col = 'token_address'
) AS
SELECT
  LOWER(token_address) AS token_address,
  DATE(block_timestamp) AS d,
  COUNT(*) AS txs
FROM `${TOKEN_TRANSFERS_TABLE}`
WHERE DATE(block_timestamp) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY) AND CURRENT_DATE()
GROUP BY token_address, d;
