#!/bin/sh
set -eu

workflows_dir="${N8N_WORKFLOWS_DIR:-/home/node/.n8n/workflows}"

if [ -d "$workflows_dir" ] && find "$workflows_dir" -maxdepth 1 -name '*.json' | grep -q .; then
  echo "Importing workflows from $workflows_dir"
  n8n import:workflow --separate --input="$workflows_dir"
else
  echo "No workflow files found in $workflows_dir"
fi

exec n8n start