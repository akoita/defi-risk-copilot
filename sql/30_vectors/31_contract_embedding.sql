CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.contract_embedding` AS
WITH emb AS (
  SELECT
    address,
    ml_generate_embedding_result AS embed
  FROM ML.GENERATE_EMBEDDING(
    MODEL `${PROJECT_ID}.${DATASET}.rm_textembedding`,
    (
      SELECT address, fp_text AS content
      FROM `${PROJECT_ID}.${DATASET}.contract_fingerprint`
      WHERE fp_text IS NOT NULL AND fp_text != ''
    )
  )
)
SELECT address, embed
FROM emb
WHERE ARRAY_LENGTH(embed) = 768;
