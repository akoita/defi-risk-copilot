#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "Missing .env. Copy .env.sample to .env and edit." && exit 1
fi

FILE="$1"
[ -z "$FILE" ] && echo "Usage: scripts/run_sql.sh path/to/file.sql" && exit 1

echo "Running $FILE ..."
if command -v envsubst >/dev/null 2>&1; then
  envsubst < "$FILE" | bq query --location=${BQ_LOCATION} --use_legacy_sql=false --project_id=${PROJECT_ID}
else
  # Fallback: simple cat (will not substitute vars). Install gettext-base for envsubst if needed.
  bq query --location=${BQ_LOCATION} --use_legacy_sql=false --project_id=${PROJECT_ID} < "$FILE"
fi
