-- Build a simple text fingerprint per contract using logs (30d) without decoded events
-- Uses topic0 hash as an event surrogate. Works on `bigquery-public-data.crypto_ethereum.logs`.
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.contract_fingerprint` AS
WITH agg AS (
  SELECT
    LOWER(address) AS address,
    LOWER(topics[SAFE_OFFSET(0)]) AS event_sig_hash,
    COUNT(*) AS c
  FROM `${LOGS_TABLE}`
  WHERE DATE(block_timestamp) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
  GROUP BY address, event_sig_hash
)
SELECT
  address,
  STRING_AGG(CONCAT(event_sig_hash, ':', CAST(c AS STRING)), ' | ' ORDER BY c DESC) AS fp_text
FROM agg
GROUP BY address;
