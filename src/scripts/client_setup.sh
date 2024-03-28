# This script creates and configures a client within a Keycloak realm:
# 1. Checks if a client exists. If not, it creates a new client.
# 2. Updates the client configurations.

echo
echo "${BLUE}Creating client: $KEYCLOAK_CLIENT_ID${DEFAULT}"

getClient() {
    local REALM_NAME=$1
    local CLIENT_ID=$2

    local ID=$(KCADM get clients -r "$REALM_NAME" --fields id,clientId | jq -r --arg CLIENT_ID "$CLIENT_ID" '.[] | select(.clientId==$CLIENT_ID) | .id')
    echo "$ID"
}

createClient() {
    local REALM_NAME=$1
    local CLIENT_ID=$2
    
    local ID=$(getClient "$REALM_NAME" "$CLIENT_ID")
    if [[ -z "$ID" ]]; then
        KCADM create clients -r "$REALM_NAME" -s clientId="$CLIENT_ID" -s enabled=true
        ID=$(getClient "$REALM_NAME" "$CLIENT_ID") # Re-fetch ID of the newly created client
    else
        echo "Client $CLIENT_ID already exists." >&2
    fi
    echo "$ID"
}

getClientScope() {
    local REALM_NAME=$1
    local CLIENT_ID=$2
    local ID=$3 # Client ID
    
    local SCOPE_ID=$(KCADM get clients/$ID/protocol-mappers/models -r "$REALM_NAME" | jq -r --arg NAME "${CLIENT_ID}-audience" '.[] | select(.name==$NAME) | .id')
    echo "$SCOPE_ID"
}

createClientScope() {
    local REALM_NAME=$1
    local CLIENT_ID=$2
    local ID=$3 # Client ID

    local SCOPE_ID=$(getClientScope "$REALM_NAME" "$CLIENT_ID" "$ID")
    if [[ -z "$SCOPE_ID" ]]; then
        KCADM create clients/$ID/protocol-mappers/models -r $REALM_NAME \
        -s name=${CLIENT_ID}-audience \
        -s protocol=openid-connect \
        -s protocolMapper=oidc-audience-mapper \
        -s config="{\"included.client.audience\" : \"$CLIENT_ID\",\"id.token.claim\" : \"true\",\"access.token.claim\" : \"true\"}"
        echo "Client scope ${CLIENT_ID}-audience created."
    else
        echo "Client scope ${CLIENT_ID}-audience already exists."
    fi
}

ID=$(createClient "$KEYCLOAK_REALM" "$KEYCLOAK_CLIENT_ID")
KCADM update clients/"$ID" -r "$KEYCLOAK_REALM" \
  -s protocol=openid-connect \
  -s publicClient=false \
  -s clientAuthenticatorType=client-secret \
  -s standardFlowEnabled=true \
  -s directAccessGrantsEnabled=true \
  -s 'redirectUris=["https://www.keycloak.org/app/*"]' \
  -s 'webOrigins=["*"]'


# Create client scopes
createClientScope "$KEYCLOAK_REALM" "$KEYCLOAK_CLIENT_ID" "$ID"