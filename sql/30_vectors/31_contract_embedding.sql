-- Use Vertex embedding model via BigQuery remote model to embed fingerprints
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.contract_embedding` AS
SELECT
  address,
  (ML.GENERATE_EMBEDDING(MODEL `${PROJECT_ID}.${DATASET}.rm_textembedding`, fp_text)).embedding AS embed
FROM `${PROJECT_ID}.${DATASET}.contract_fingerprint`;
