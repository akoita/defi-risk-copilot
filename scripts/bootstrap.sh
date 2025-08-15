#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "Missing .env. Copy .env.sample to .env and edit." && exit 1
fi

bq --location=${BQ_LOCATION} mk --dataset --description "DeFi Risk Copilot" ${PROJECT_ID}:${DATASET} || true
echo "Dataset ensured: ${PROJECT_ID}.${DATASET} (${BQ_LOCATION})"
