#!/bin/bash

set -e

echo "Starting services with Docker Compose..."
docker compose up -d

echo "Waiting for domserver to be ready..."

# Wait until domserver is responding
until docker exec domserver curl -s http://localhost >/dev/null 2>&1; do
  echo "Still waiting for domserver to respond at http://localhost..."
  sleep 3
done

echo "domserver is up."

echo "Getting judgehost password from restapi.secret..."
JUDGEDAEMON_PASSWORD=$(docker exec domserver sh -c "awk 'NR==3 {print \$4}' /opt/domjudge/domserver/etc/restapi.secret")

if [ -z "$JUDGEDAEMON_PASSWORD" ]; then
  echo "Failed to get judgehost password."
  exit 1
fi

echo "Password found: $JUDGEDAEMON_PASSWORD"

# Find Docker Compose default network dynamically (matches *_default)
COMPOSE_NETWORK=$(docker network ls --format '{{.Name}}' | grep '_default$' | head -n 1)

if [ -z "$COMPOSE_NETWORK" ]; then
  echo "Could not find a Docker Compose network ending with '_default'."
  exit 1
fi

echo "Using network: $COMPOSE_NETWORK"

# Detect domserver image version/tag
DOMSERVER_IMAGE=$(docker inspect domserver --format='{{.Config.Image}}')
JUDGEHOST_IMAGE=${DOMSERVER_IMAGE/domserver/judgehost}

echo "Detected DOMserver image: $DOMSERVER_IMAGE"
echo "Using judgehost image: $JUDGEHOST_IMAGE"

# Remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^judgehost-0$"; then
  echo "Removing existing judgehost-0 container..."
  docker rm -f judgehost-0
fi

echo "Starting judgehost-0 on network $COMPOSE_NETWORK..."
docker run -d --privileged \
  --network "$COMPOSE_NETWORK" \
  -v /sys/fs/cgroup:/sys/fs/cgroup \
  --name judgehost-0 \
  --hostname judgedaemon-0 \
  -e DAEMON_ID=0 \
  -e JUDGEDAEMON_USERNAME=judgehost \
  -e JUDGEDAEMON_PASSWORD="$JUDGEDAEMON_PASSWORD" \
  "$JUDGEHOST_IMAGE"

echo "All containers started successfully."
