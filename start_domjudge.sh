#!/bin/bash

set -e

#Start Docker Compose services in detached mode
docker compose up -d >/dev/null
echo "Docker Compose containers are up."

#Wait for domserver to respond
until docker exec domserver curl -s http://localhost >/dev/null 2>&1; do
  sleep 2
done

#Get judgehost password
JUDGEDAEMON_PASSWORD=$(docker exec domserver sh -c "awk 'NR==3 {print \$4}' /opt/domjudge/domserver/etc/restapi.secret")

if [ -z "$JUDGEDAEMON_PASSWORD" ]; then
  echo "Could not retrieve judgehost password."
  exit 1
fi

#Find Docker Compose network (matches *_default)
COMPOSE_NETWORK=$(docker network ls --format '{{.Name}}' | grep '_default$' | head -n 1)

if [ -z "$COMPOSE_NETWORK" ]; then
  echo "Could not find Docker Compose default network."
  exit 1
fi

#Remove existing judgehost-0 if present
if docker ps -a --format '{{.Names}}' | grep -q "^judgehost-0$"; then
  docker rm -f judgehost-0 >/dev/null
fi

#Start judgehost-0 in detached mode
docker run -d --privileged \
  --network "$COMPOSE_NETWORK" \
  -v /sys/fs/cgroup:/sys/fs/cgroup \
  --name judgehost-0 \
  --hostname judgedaemon-0 \
  -e DAEMON_ID=0 \
  -e JUDGEDAEMON_USERNAME=judgehost \
  -e JUDGEDAEMON_PASSWORD="$JUDGEDAEMON_PASSWORD" \
  domjudge/judgehost:latest >/dev/null

echo "judgehost-0 container started."
