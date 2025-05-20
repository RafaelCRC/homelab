#!/bin/bash

# Configuration
CF_ACCOUNT_ID="your_account_id"
CF_LOCALNETWORK_POLICY_ID="your_policy_id"
CF_API_TOKEN="your_access_api_token"
CF_ZONE_ID="your_zone_id"
CF_DNS_RECORD_ID="your_dns_record_id"
CF_DNS_RECORD_NAME="home.example.com"
CF_API_TOKEN_DNS="your_dns_api_token"

# File to store the last IP
IP_FILE="/cloudflare/last_ip.txt"
LOG_FILE="/cloudflare/logs/flarelog.log"

# Create directories if they don't exist
mkdir -p "$(dirname "$IP_FILE")" "$(dirname "$LOG_FILE")"

# Get current IP
CURRENT_IP=$(curl -s ifconfig.me)
if [ -z "$CURRENT_IP" ]; then
    # If couldn't get the IP, try a different service
    CURRENT_IP=$(curl -s icanhazip.com)
    if [ -z "$CURRENT_IP" ]; then
        echo "$(date) - ERROR: Failed to get current IP address" >> "$LOG_FILE"
        exit 1
    fi
fi

# Check if IP has changed
if [ -f "$IP_FILE" ]; then
    LAST_IP=$(cat "$IP_FILE")
else
    LAST_IP=""
fi

if [ "$CURRENT_IP" == "$LAST_IP" ]; then
    # IP hasn't changed, exit silently
    exit 0
fi

# IP has changed, proceed with updates
echo "$(date) - IP changed from ${LAST_IP:-none} to $CURRENT_IP" >> "$LOG_FILE"

# Update Cloudflare Access Policy
echo "$(date) - Updating Cloudflare Access Policy..." >> "$LOG_FILE"
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/access/policies/$CF_LOCALNETWORK_POLICY_ID" \
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
  }')

# Check if the update was successful
if  echo "$RESPONSE" | grep -q -E '"success":\s*true\b'; then
    echo "$(date) - Access Policy updated successfully" >> "$LOG_FILE"
else
    echo "$(date) - ERROR: Failed to update Access Policy" >> "$LOG_FILE"
    echo "Full response:" >> "$LOG_FILE"
    echo "$RESPONSE" >> "$LOG_FILE"
    exit 1
fi

# Update Cloudflare DNS Record
echo "$(date) - Updating Cloudflare DNS Record..." >> "$LOG_FILE"
RESPONSE=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$CF_DNS_RECORD_ID" \
  -H "Authorization: Bearer $CF_API_TOKEN_DNS" \
  -H "Content-Type:application/json" \
  -d '{
    "comment": "Script managed, DO NOT TOUCH!",
    "content": "'"$CURRENT_IP"'",
    "name": "'"$CF_DNS_RECORD_NAME"'",
    "proxied": false,
    "ttl": 1,
    "type": "A"
  }')

# Check if the update was successful
if  echo "$RESPONSE" | grep -q -E '"success":\s*true\b'; then
    echo "$(date) - DNS Record updated successfully" >> "$LOG_FILE"
else
    echo "$(date) - ERROR: Failed to update DNS Record" >> "$LOG_FILE"
    echo "Full response:" >> "$LOG_FILE"
    echo "$RESPONSE" >> "$LOG_FILE"
    exit 1
fi

# Store the new IP
echo "$CURRENT_IP" > "$IP_FILE"
echo "$(date) - Successfully updated Cloudflare with new IP" >> "$LOG_FILE"