#!/bin/bash

set -e

CONTAINER_NAME="phpmyadmin"

echo "Restarting container: $CONTAINER_NAME..."

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  docker restart "$CONTAINER_NAME"
  echo "$CONTAINER_NAME restarted successfully."
else
  echo "Container '$CONTAINER_NAME' not found."
  exit 1
fi
