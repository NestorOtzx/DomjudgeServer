#!/bin/bash

set -e

echo "Fetching initial admin password..."
ADMIN_PASSWORD=$(docker exec domserver cat /opt/domjudge/domserver/etc/initial_admin_password.secret)

if [ -z "$ADMIN_PASSWORD" ]; then
  echo "Failed to retrieve admin password."
  exit 1
fi

echo "Admin password:"
echo "$ADMIN_PASSWORD"
echo

echo "Fetching judgehost (API) credentials..."
RESTAPI_SECRET=$(docker exec domserver cat /opt/domjudge/domserver/etc/restapi.secret)

if [ -z "$RESTAPI_SECRET" ]; then
  echo "Failed to retrieve restapi.secret file."
  exit 1
fi

echo "Judgehost username and password:"
echo "$RESTAPI_SECRET" | awk 'NR==3 {print "Username: " $3 "\nPassword: " $4}'
