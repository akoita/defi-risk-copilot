# Looker Studio – 1-Page Dashboard Spec

**Data source**: BigQuery, project `${PROJECT_ID}`, dataset `${DATASET}`.

## Layout
- **Header**: title, date range control (last 30 days default).
- **Left column (Alerts)**
  - Table: `token_alerts`
    - Dimensions: token_address
    - Metrics: vol_30d, vol_z, top100_share, lp_removed_30d
    - Style: conditional formatting (vol_z > 2 red, top100_share > 0.4 amber, lp_removed_30d > 0 red)
  - Text box bound to `explanation` (use data control or a record-details section).

- **Right column (Trends & Similarity)**
  - Time series: Token transfer volume (bind to a daily txs-by-token view or blend data).
  - Table: `similar_contracts`
    - Dimensions: address, neighbor_address
    - Metric: distance (ascending)

## Filters
- Token search (text filter on token_address)
- Risk toggles (checkbox-style): vol_z>2, top100_share>0.4, lp_removed_30d>0

## Tips
- Use a parameter `p_token` to drive both the detail text (explanation) and the time series via a filter.
- Keep one page. Judges value clarity.
