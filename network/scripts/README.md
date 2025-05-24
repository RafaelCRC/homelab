# **Cloudflare Dynamic IP Updater**

Automatically update Cloudflare Access Policies and DNS records when your public IP changes. Ideal for home networks with dynamic IPs.

![alt text](/assets/network/cloudflare_script.png)

## Navigation
* [Apps](/apps/README.md) - List of all the apps and services.
* [Dashboard](/dashboard/README.md) - Dashboards and monitoring tools.
* [Network](/network/README.md) - Network scripts and Cloudflare setup.
  - [Adguard Home](/network/adguardHome/README.md) - Adguard DNS Server.
  - [DNSS](/network/dnss/README.md) - Container to update Cloudflare records with public ip.
  - [Nginx Proxy Manager](/network/nginx/README.md) - Nginx proxy manager.
  - [__Scripts__](/network/scripts/README.md) - Scripts for network and cloudflare.
  - [Wireguard](/network/wireguard/README.md) - Wireguard VPN Server.
* [Home Assistant](/homeassistant/README.md) - Smart home services and automation.
* [Server Monitoring](/monitoring/README.md) - Server Monitoring services.
* [Tools](/tools/README.md) - Tools that makes life easier.


WIP

## **Features**
- Checks public IP every 5 minutes
- Updates Cloudflare Access Policy & DNS A record only if IP changes
- Minimal logging (only logs changes/errors)
- Supports log rotation to prevent large log files
- Error handling with backup IP detection

---

## **Prerequisites**
- Linux server (or Raspberry Pi) with `cron` and `logrotate`
- Cloudflare account with:
  - **Access Policy** (Zero Trust) for IP bypass
  - **DNS A record** you want to update
- `curl` installed

---

## **Setup Guide**

### **1. Get Cloudflare API Credentials**
#### **A. Cloudflare API Token (for DNS)**
1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click **Create Token** > Use template **Edit zone DNS**
3. Select the zone (domain) to update
4. Copy the generated token → `CF_API_TOKEN_DNS`

#### **B. Cloudflare Account ID & Policy ID (for Access)**
1. Go to [Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Access** > **Policies**
3. Find your "Local Network" policy and note its ID → `CF_LOCALNETWORK_POLICY_ID`
4. Get your **Account ID** from the dashboard URL or profile → `CF_ACCOUNT_ID`
5. Create an **API Token** (with Access:Edit permissions) → `CF_API_TOKEN`

#### **C. DNS Zone & Record ID**
1. Go to **DNS** > **Records**
2. Find your A record and note:
   - **Zone ID** (from dashboard URL) → `CF_ZONE_ID`
   - **Record ID** (click record, check URL) → `CF_DNS_RECORD_ID`
   - **Record name** (e.g., `home.example.com`) → `CF_DNS_RECORD_NAME`

---

### **2. Install the Script**
#### **A. Save the Script**
```bash
sudo mkdir -p /cloudflare/
sudo nano /cloudflare/flareipupdate.sh
```
Paste this script (update variables first!):
```bash
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
```
Make it executable:
```bash
sudo chmod +x /cloudflare/flareipupdate.sh
```
---

## **Note**

if you use [ddns](/network/dnss/README.md) you dont need the "DNS Record updating" part of the script

---

### **3. Configure Crontab (Runs Every 5 Minutes)**
```bash
sudo crontab -e
```
Add this line:
```bash
*/5 * * * * /cloudflare/flareipupdate.sh >> /cloudflare/logs/flarelog.log 2>&1
```

---

### **4. Set Up Log Rotation**
Create a logrotate config:
```bash
sudo nano /etc/logrotate.d/cloudflare_ip_updater
```
Paste this:
```bash
/cloudflare/logs/flarelog.log {  # Log file to rotate
    daily                        # Rotate logs every day
    rotate 7                     # Keep 7 rotated logs (1 week)
    compress                     # Compress old logs (saves space)
    missingok                    # Don't error if log is missing
    notifempty                   # Skip rotation if log is empty
    create 0644 root root        # Recreate log with these permissions
    dateext                      # Append date to rotated logs (e.g., .log-20250521.gz)
}
```
Test it:
```bash
sudo logrotate -vf /etc/logrotate.d/cloudflare_ip_updater
```

---

## **Troubleshooting**
- **Check logs**:  
  ```bash
  cat /cloudflare/logs/flarelog.log
  ```
- **Manual test**:  
  ```bash
  /cloudflare/flareipupdate.sh
  ```
- **Verify cron**:  
  ```bash
  sudo tail -f /var/log/syslog | grep CRON
  ```

---

### **Why This Works**
- **Efficient**: Only calls Cloudflare API when IP changes.
- **Reliable**: Uses two IP check services (`ifconfig.me` + `icanhazip.com`).
- **Clean logs**: No spam, only changes/errors.
- **Self-maintaining**: Logs rotate automatically.  

