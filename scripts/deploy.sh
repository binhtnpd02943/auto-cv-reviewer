#!/bin/bash
set -Eeuo pipefail

# Scripts must be run from project root
cd "$(dirname "$0")/.."

echo "Starting deployment process..."

# Define variables
COMPOSE_FILE="docker-compose.yml"
APP_CONTAINER="auto-cv-reviewer-app"

# Check if docker and docker compose are installed
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed."
    exit 1
fi

# Pull latest code if on a VM (optional, assume already pulled by CI or here)
# git pull origin main

echo "Building and starting containers in detached mode..."
docker compose -f "$COMPOSE_FILE" up -d --build

echo "Cleaning up dangling images to save disk space..."
docker image prune -f

echo "Deployment step completed successfully."
