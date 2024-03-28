#!/usr/bin/env bash

# Entrypoint into Keycloak. It uses Keycloak Admin CLI (KCADM)
# to setup realms, clients, and users for candig services.

set -euo pipefail

# Terminal colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
DEFAULT='\033[0m'

####################################################
#              VARIABLES CONFIGURATION             #
####################################################
# KEYCLOAK_VERSION=24.0.0
KEYCLOAK_ADMIN=$(cat ../secrets/kc-admin-user.txt)
KEYCLOAK_ADMIN_PASSWORD=$(cat ../secrets/kc-admin-password.txt)
READY_CHECK_URL="http://localhost:8080/health/ready"
KC_ADMIN_URL="http://host.docker.internal:8080"
KEYCLOAK_REALM="myrealm"
KEYCLOAK_CLIENT_ID="myclient"
#####################################################

echo "🚧🚧🚧 ${YELLOW}KEYCLOAK SETUP BEGIN${DEFAULT} 🚧🚧🚧"
echo ">> waiting for keycloak to start"
# keycloak booting up before it can accept requests
until $(curl --output /dev/null --silent --fail --head "${READY_CHECK_URL}"); do
    printf '.'
    sleep 1
done
echo "\n${GREEN}Keycloak is ready!${DEFAULT}"

# Get the Keycloak container ID
KEYCLOAK_CONTAINER_ID=$(docker ps | grep keycloak/keycloak | awk '{print $1}')
# Define the KCADM function to run commands inside the Keycloak container
function KCADM() {
    docker exec "$KEYCLOAK_CONTAINER_ID" /opt/keycloak/bin/kcadm.sh "$@"
}
# authenticate as admin
KCADM config credentials --server $KC_ADMIN_URL --user $KEYCLOAK_ADMIN --password $KEYCLOAK_ADMIN_PASSWORD --realm master

# create realm
source ./realm_setup.sh
# create client
source ./client_setup.sh
# create test users
source ./user_setup.sh

echo "🎉🎉🎉 ${GREEN}KEYCLOAK SETUP DONE!${DEFAULT} 🎉🎉🎉"
