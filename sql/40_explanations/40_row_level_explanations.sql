-- Generate concise natural-language explanations for token risk rows
CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET}.token_explanations` AS
SELECT
  t.token_address,
  ML.GENERATE_TEXT(
    MODEL `${PROJECT_ID}.${DATASET}.rm_gemini_15_flash`,
    STRUCT(
      CONCAT(
        'Explain in 2 short sentences, no hype. ',
        'If risky, mention holder concentration and LP removals. ',
        'Features: top100_share=', CAST(t.top100_share AS STRING),
        ', lp_removed_30d=', CAST(t.lp_removed_30d AS STRING),
        ', vol_z=', CAST(t.vol_z AS STRING)
      ) AS prompt,
      256 AS max_output_tokens
    )
  ).content AS explanation,
  CURRENT_TIMESTAMP() AS generated_at
FROM `${PROJECT_ID}.${DATASET}.token_features` t
WHERE (t.vol_z > 2 OR t.top100_share > 0.4 OR t.lp_removed_30d > 0);
