-- Incremental append-only: ensure table exists, then insert only missing or stale rows
CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.${DATASET}.token_explanations` (
  token_address STRING,
  explanation STRING,
  generated_at TIMESTAMP
);

INSERT INTO `${PROJECT_ID}.${DATASET}.token_explanations` (token_address, explanation, generated_at)
SELECT
  t.token_address,
  (
    SELECT JSON_VALUE(ml_generate_text_result, '$.candidates[0].content.parts[0].text')
    FROM ML.GENERATE_TEXT(
      MODEL `${PROJECT_ID}.${DATASET}.rm_gemini_25_flash`,
      (
        SELECT CONCAT(
          'Explain in 1 short sentence. ',
          'Features: top100_share=', CAST(t.top100_share AS STRING),
          ', lp_removed_7d=', CAST(t.lp_removed_7d AS STRING),
          ', vol_z=', CAST(t.vol_z AS STRING)
        ) AS prompt
      ),
      STRUCT(128 AS max_output_tokens)
    )
  ) AS explanation,
  CURRENT_TIMESTAMP() AS generated_at
FROM `${PROJECT_ID}.${DATASET}.token_features` t
LEFT JOIN `${PROJECT_ID}.${DATASET}.token_explanations` e USING (token_address)
WHERE (t.vol_z > 3 OR t.top100_share > 0.6 OR t.lp_removed_7d > 0)
  AND (e.token_address IS NULL OR e.generated_at < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY))
QUALIFY ROW_NUMBER() OVER (ORDER BY t.vol_z DESC, t.top100_share DESC, t.lp_removed_7d DESC) <= 100;
