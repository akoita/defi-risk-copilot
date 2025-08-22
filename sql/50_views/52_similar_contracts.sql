-- For each contract, find 5 nearest neighbors by event-fingerprint embedding
-- OPTIMIZED: Limits scope and adds performance hints
CREATE OR REPLACE VIEW `${PROJECT_ID}.${DATASET}.similar_contracts` AS
WITH q AS (
  SELECT address, embed 
  FROM `${PROJECT_ID}.${DATASET}.contract_embedding`
  -- Limit scope for better performance - adjust this number as needed
  LIMIT 1000
)
SELECT
  q.address AS address,
  nbr.base.address AS neighbor_address,
  nbr.distance
FROM VECTOR_SEARCH(
  TABLE `${PROJECT_ID}.${DATASET}.contract_embedding`,
  'embed',
  TABLE q,
  query_column_to_search => 'embed',
  top_k => 5,
  distance_type => 'COSINE'
) AS nbr
JOIN q ON TRUE
WHERE nbr.base.address != q.address;
