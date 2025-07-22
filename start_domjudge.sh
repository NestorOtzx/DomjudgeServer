#!/bin/bash

set -e

echo "Starting services with Docker Compose..."
docker compose up -d

echo "Waiting for domserver to be ready..."

#Wait until domserver is responding
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

#Use Docker Compose network (assuming it's domjudge_default)
COMPOSE_NETWORK="domjudge_default"

#Remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^judgehost-0$"; then
  echo "Removing existing judgehost-0 container..."
  docker rm -f judgehost-0
fi

echo "Starting judgehost-0 on network $COMPOSE_NETWORK..."
docker run -it --privileged \
  --network "$COMPOSE_NETWORK" \
  -v /sys/fs/cgroup:/sys/fs/cgroup \
  --name judgehost-0 \
  --hostname judgedaemon-0 \
  -e DAEMON_ID=0 \
  -e JUDGEDAEMON_USERNAME=judgehost \
  -e JUDGEDAEMON_PASSWORD="$JUDGEDAEMON_PASSWORD" \
  domjudge/judgehost:latest
