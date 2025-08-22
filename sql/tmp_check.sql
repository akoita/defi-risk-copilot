SELECT *
FROM ML.GENERATE_TEXT(
  MODEL `${PROJECT_ID}.${DATASET}.rm_gemini_25_flash`,
  (SELECT 'hello' AS prompt),
  STRUCT(64 AS max_output_tokens)
);


