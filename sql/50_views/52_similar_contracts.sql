-- For each contract, find 5 nearest neighbors by event-fingerprint embedding
CREATE OR REPLACE VIEW `${PROJECT_ID}.${DATASET}.similar_contracts` AS
WITH q AS (
  SELECT address, embed FROM `${PROJECT_ID}.${DATASET}.contract_embedding`
)
SELECT
  src.address AS address,
  nbr.neighbor_id AS neighbor_address,
  nbr.distance
FROM VECTOR_SEARCH(
  TABLE `${PROJECT_ID}.${DATASET}.contract_embedding`,
  'embed',
  TABLE q,
  STRUCT(5 AS top_k)
) AS nbr
JOIN q src ON TRUE
WHERE nbr.neighbor_id != src.address;
