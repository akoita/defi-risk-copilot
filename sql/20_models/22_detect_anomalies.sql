-- Produce anomaly flags for addresses (contamination 10%)
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.address_anomalies` AS
SELECT *
FROM ML.DETECT_ANOMALIES(
  MODEL `${PROJECT_ID}.${DATASET}.kmeans_addresses`,
  STRUCT(0.1 AS contamination),
  TABLE `${PROJECT_ID}.${DATASET}.address_features`
);

-- Optional: forecast and compute residual spikes for tokens
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.token_forecast` AS
SELECT *
FROM ML.FORECAST(MODEL `${PROJECT_ID}.${DATASET}.arima_token_volume`, STRUCT(7 AS horizon, 0.8 AS confidence_level));
