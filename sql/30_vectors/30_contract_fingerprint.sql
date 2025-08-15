-- Build a simple text fingerprint per contract using decoded events (30d)
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.contract_fingerprint` AS
WITH agg AS (
  SELECT
    LOWER(contract_address) AS address,
    event_name,
    COUNT(*) AS c
  FROM `bigquery-public-data.blockchain_analytics.ethereum_mainnet.decoded_events`
  WHERE _PARTITIONDATE BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
  GROUP BY address, event_name
)
SELECT
  address,
  STRING_AGG(CONCAT(event_name, ':', CAST(c AS STRING)), ' | ' ORDER BY c DESC) AS fp_text
FROM agg
GROUP BY address;
