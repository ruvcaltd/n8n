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
  sudo mkdir -p ${REMOTE_PATH}
  sudo rsync -avz --delete /tmp/n8n-deploy/ ${REMOTE_PATH}/
  cd ${REMOTE_PATH}
  if [ ! -f .env ]; then
    echo '.env missing on VPS; copy it to /opt/n8n/.env'
    exit 1
  fi
  docker compose pull
  docker compose up -d
  docker compose ps
  rm -rf /tmp/n8n-deploy
EOF
