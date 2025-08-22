#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: scripts/run_with_retry.sh path/to/file.sql [retries=3] [base_sleep_sec=10]" >&2
  exit 1
fi

SQL_FILE="$1"
RETRIES="${2:-3}"
BASE_SLEEP="${3:-10}"

ATTEMPT=1
while true; do
  echo "Attempt ${ATTEMPT}/${RETRIES}: ${SQL_FILE}"
  if bash "$(dirname "$0")/run_sql.sh" "$SQL_FILE"; then
    exit 0
  fi
  if [ "$ATTEMPT" -ge "$RETRIES" ]; then
    echo "Failed after ${RETRIES} attempts: ${SQL_FILE}" >&2
    exit 1
  fi
  SLEEP_SEC=$((BASE_SLEEP * ATTEMPT))
  echo "Retrying in ${SLEEP_SEC}s..." >&2
  sleep "$SLEEP_SEC"
  ATTEMPT=$((ATTEMPT + 1))
done


