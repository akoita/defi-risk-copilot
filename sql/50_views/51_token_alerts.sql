-- Final view: risky tokens (features + simple rule + explanation)
CREATE OR REPLACE VIEW `${PROJECT_ID}.${DATASET}.token_alerts` AS
SELECT
  t.token_address,
  t.vol_30d,
  t.vol_z,
  t.top100_share,
  t.lp_added_30d,
  t.lp_removed_30d,
  COALESCE(e.explanation, 'No major red flags in 30d window.') AS explanation,
  t.updated_at
FROM `${PROJECT_ID}.${DATASET}.token_features` t
LEFT JOIN `${PROJECT_ID}.${DATASET}.token_explanations` e USING(token_address)
WHERE (t.vol_z > 2 OR t.top100_share > 0.4 OR t.lp_removed_30d > 0);
