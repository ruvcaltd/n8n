#!/bin/bash
set -e

# Initialize n8n database schema

echo "Starting PostgreSQL..."
docker-compose up -d postgres

echo "Waiting for PostgreSQL to be ready..."
sleep 10

echo "Creating database schema..."
docker-compose exec -T postgres psql -U n8n -d n8n < schema.sql

echo "Database initialized successfully!"

echo "Starting n8n..."
docker-compose up -d n8n

echo "Waiting for n8n container to accept commands..."
attempts=0
until docker-compose exec -T n8n true >/dev/null 2>&1; do
  attempts=$((attempts + 1))
  if [ ${attempts} -ge 24 ]; then
    echo "Timed out waiting for n8n container to start"
    docker-compose logs --tail=100 n8n
    exit 1
  fi
  sleep 5
done

echo "Importing workflows into n8n..."
docker-compose exec -T n8n n8n import:workflow --separate --input=/home/node/.n8n/workflows

echo "Setup complete! Access n8n at http://localhost:5678"