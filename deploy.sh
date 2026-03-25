#!/bin/bash
set -e

if [ -z "$VPS_HOST" ] || [ -z "$VPS_USER" ]; then
  echo "VPS_HOST and VPS_USER must be set"
  exit 1
fi

REMOTE_PATH="/opt/n8n"

rsync -avz --delete --exclude '.git' --exclude '.github' . ${VPS_USER}@${VPS_HOST}:/tmp/n8n-deploy
ssh -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_HOST} <<'EOF'
  set -e
  REMOTE_PATH="/opt/n8n"
  sudo mkdir -p ${REMOTE_PATH}
  sudo rsync -avz --delete /tmp/n8n-deploy/ ${REMOTE_PATH}/
  cd ${REMOTE_PATH}
  if [ ! -f .env ]; then
    echo '.env missing on VPS; copy it to /opt/n8n/.env'
    exit 1
  fi
  docker compose pull
  docker compose up -d --force-recreate

  echo 'Waiting for workflow import log entry...'
  import_attempts=0
  until docker compose logs --no-color n8n 2>&1 | grep -q 'Importing workflows from'; do
    import_attempts=$((import_attempts + 1))
    if [ ${import_attempts} -ge 24 ]; then
      echo 'Timed out waiting for n8n workflow import to start.'
      docker compose logs --no-color n8n | tail -n 100
      exit 1
    fi
    sleep 5
  done

  echo 'Workflow import detected in n8n startup logs.'
  docker compose ps
  rm -rf /tmp/n8n-deploy
EOF
