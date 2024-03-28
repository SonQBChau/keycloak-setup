#!/bin/bash

# Load credentials from secrets
export KEYCLOAK_ADMIN=$(< /run/secrets/kc-admin-user)
export KEYCLOAK_ADMIN_PASSWORD=$(< /run/secrets/kc-admin-password)

exec /opt/keycloak/bin/kc.sh "$@"