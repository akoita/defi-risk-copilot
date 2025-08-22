-- (Idempotent) No-op if dataset exists. Included for documentation.
-- Create the dataset in US location via CLI or UI. SQL shown for reference only.
-- CREATE SCHEMA `${PROJECT_ID}.${DATASET}` OPTIONS(location="US");

-- No-op query so the runner executes cleanly
SELECT 1 AS ok;
