#!/bin/bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  COMPOSE_CMD=(docker compose)
else
  COMPOSE_CMD=("$@")
fi

echo 'Waiting for n8n container to accept commands...'
attempts=0
until "${COMPOSE_CMD[@]}" exec -T n8n true >/dev/null 2>&1; do
  attempts=$((attempts + 1))
  if [ "${attempts}" -ge 24 ]; then
    echo 'Timed out waiting for n8n container to start.'
    "${COMPOSE_CMD[@]}" logs --no-color n8n | tail -n 100
    exit 1
  fi
  sleep 5
done

echo 'Resolving n8n owner user...'
owner_attempts=0
OWNER_ID=''
until [ -n "${OWNER_ID}" ]; do
  OWNER_ID=$("${COMPOSE_CMD[@]}" exec -T postgres psql -U n8n -d n8n -Atqc 'SELECT id FROM "user" LIMIT 1;' 2>/dev/null | tr -d '\r')
  if [ -n "${OWNER_ID}" ]; then
    break
  fi

  owner_attempts=$((owner_attempts + 1))
  if [ "${owner_attempts}" -ge 12 ]; then
    echo 'No n8n owner user found yet. Skipping workflow import to avoid creating workflows that are not visible in the UI.'
    echo 'Complete the n8n owner signup flow, then rerun: bash ./import-workflows.sh' "$@"
    exit 0
  fi
  sleep 5
done

IMPORT_ARGS=(import:workflow --separate --input=/home/node/.n8n/workflows)
echo "Importing workflows into n8n for user ${OWNER_ID}..."
IMPORT_ARGS+=(--userId="${OWNER_ID}")

"${COMPOSE_CMD[@]}" exec -T n8n n8n "${IMPORT_ARGS[@]}"

WORKFLOW_COUNT=$("${COMPOSE_CMD[@]}" exec -T postgres psql -U n8n -d n8n -Atqc 'SELECT COUNT(*) FROM workflow_entity;' 2>/dev/null | tr -d '\r')
if [ -n "${WORKFLOW_COUNT}" ]; then
  echo "Workflow rows in database: ${WORKFLOW_COUNT}"
fi

echo 'Restarting n8n so imported workflows are reloaded from the database...'
"${COMPOSE_CMD[@]}" restart n8n >/dev/null

echo 'Waiting for n8n to come back after restart...'
attempts=0
until "${COMPOSE_CMD[@]}" exec -T n8n true >/dev/null 2>&1; do
  attempts=$((attempts + 1))
  if [ "${attempts}" -ge 24 ]; then
    echo 'Timed out waiting for n8n after restart.'
    "${COMPOSE_CMD[@]}" logs --no-color n8n | tail -n 100
    exit 1
  fi
  sleep 5
done

echo 'Workflow import completed.'