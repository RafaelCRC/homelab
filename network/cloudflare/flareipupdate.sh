#!/bin/bash

CF_ACCOUNT_ID="your_account_id"
CF_LOCALNETWORK_POLICY_ID="your_policy_id"
CF_API_TOKEN="your_api_token"

CURRENT_IP=$(curl -s ifconfig.me)

curl -X PUT "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/access/policies/$CF_LOCALNETWORK_POLICY_ID" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Allow Home IP",
    "decision": "bypass",
    "include": [
      {
        "ip": {
          "ip": "'"$CURRENT_IP"'/32"
        }
      }
    ]
  }'