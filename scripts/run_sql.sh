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
bq query   --location=${BQ_LOCATION}   --use_legacy_sql=false   --project_id=${PROJECT_ID}   "$(cat $FILE)"
