#!/bin/bash

set -e

echo "Stopping and removing Docker Compose services..."
docker compose down --remove-orphans >/dev/null
echo "Docker Compose services stopped."

# Stop and remove judgehost container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^judgehost-0$"; then
  echo "Removing judgehost-0 container..."
  docker rm -f judgehost-0 >/dev/null
  echo "judgehost-0 container removed."
fi

# Optionally remove the *_default Docker network
COMPOSE_NETWORK=$(docker network ls --format '{{.Name}}' | grep '_default$' | head -n 1)
if [ -n "$COMPOSE_NETWORK" ]; then
  echo "!!!! Removing Docker Compose default network: $COMPOSE_NETWORK"
  docker network rm "$COMPOSE_NETWORK" >/dev/null || true
fi


echo "All DOMjudge containers and networks stopped and cleaned."
