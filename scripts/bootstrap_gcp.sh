#!/usr/bin/env bash
set -euo pipefail

# Bootstrap required GCP services and IAM for this project
# - Enables required APIs
# - Creates BigQuery Cloud Resource connection for Vertex AI
# - Grants required roles to the connection service account
#
# Requires: gcloud, bq; optional: jq

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC2046
  export $(grep -v '^#' "$ROOT_DIR/.env" | xargs)
  set +a
else
  echo "Missing .env at $ROOT_DIR/.env. Copy .env.sample and set PROJECT_ID, DATASET, BQ_LOCATION, CONNECTION_NAME." >&2
  exit 1
fi

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud not found. Install Google Cloud SDK." >&2
  exit 1
fi

if ! command -v bq >/dev/null 2>&1; then
  echo "bq CLI not found. Install Google Cloud SDK components." >&2
  exit 1
fi

PROJECT_ID=${PROJECT_ID:?"PROJECT_ID must be set in .env"}
CONNECTION_NAME=${CONNECTION_NAME:?"CONNECTION_NAME (e.g., US.vertex_us) must be set in .env"}

# Parse location and connection id from CONNECTION_NAME like "US.vertex_us"
CONNECTION_LOC="${CONNECTION_NAME%%.*}"
CONNECTION_ID="${CONNECTION_NAME##*.}"

echo "Using project: $PROJECT_ID"
echo "Connection: location=$CONNECTION_LOC id=$CONNECTION_ID"

echo "Enabling required APIs..."
gcloud services enable \
  bigquery.googleapis.com \
  bigqueryconnection.googleapis.com \
  aiplatform.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project="$PROJECT_ID" --quiet

echo "Creating BigQuery Cloud Resource connection if missing..."
if bq --project_id="$PROJECT_ID" --location="$CONNECTION_LOC" show --connection "$CONNECTION_ID" >/dev/null 2>&1; then
  echo "Connection exists: $CONNECTION_LOC.$CONNECTION_ID"
else
  bq --project_id="$PROJECT_ID" mk --location="$CONNECTION_LOC" --connection \
    --display_name="$CONNECTION_ID" --connection_type=CLOUD_RESOURCE "$CONNECTION_ID"
  echo "Created connection: $CONNECTION_LOC.$CONNECTION_ID"
fi

echo "Fetching connection service account..."
SA_JSON=$(bq --project_id="$PROJECT_ID" --location="$CONNECTION_LOC" show --connection --format=prettyjson "$CONNECTION_ID")
if command -v jq >/dev/null 2>&1; then
  CONN_SA=$(printf '%s' "$SA_JSON" | jq -r '.cloudResource.serviceAccountId')
else
  # Fallback parse without jq
  CONN_SA=$(printf '%s' "$SA_JSON" | grep -o '"serviceAccountId"\s*:\s*"[^"]*"' | sed 's/.*:"\([^"]*\)"/\1/')
fi

if [ -z "${CONN_SA:-}" ]; then
  echo "Failed to determine connection service account. Install jq or check connection." >&2
  exit 1
fi

echo "Connection service account: $CONN_SA"

echo "Granting roles to connection service account (idempotent)..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$CONN_SA" \
  --role="roles/aiplatform.user" --quiet >/dev/null
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$CONN_SA" \
  --role="roles/bigquery.jobUser" --quiet >/dev/null
echo "Granted roles: roles/aiplatform.user, roles/bigquery.jobUser"

echo "Done. Next steps:"
echo "- Create dataset (if not exists): bash scripts/run_sql.sh sql/00_init/01_create_dataset.sql"
echo "- Create remote models: bash scripts/run_sql.sh sql/00_init/03_create_remote_models.sql"
echo "- Run pipeline: bash scripts/run_all.sh"


