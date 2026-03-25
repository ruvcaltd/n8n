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

bash ./import-workflows.sh docker-compose

echo "Setup complete! Access n8n at http://localhost:5678"