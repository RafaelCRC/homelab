# **WireGuard VPN Setup with WG-Easy**  

Self-hosted WireGuard VPN with a user-friendly web interface for secure remote access to your local network.

![alt text](/assets/network/wireguard.png)

## Navigation
* [Apps](/apps/README.md) - List of all the apps and services.
* [Dashboard](/dashboard/README.md) - Dashboards and monitoring tools.
* [Network](/network/README.md) - Network scripts and Cloudflare setup.
  - [Adguard Home](/network/adguardHome/README.md) - Adguard DNS Server.
  - [DNSS](/network/dnss/README.md) - Container to update Cloudflare records with public ip.
  - [Nginx Proxy Manager](/network/nginx/README.md) - Nginx proxy manager.
  - [Scripts](/network/scripts/README.md) - Scripts for network and cloudflare.
  - [__Wireguard__](/network/wireguard/README.md) - Wireguard VPN Server.
* [Home Assistant](/homeassistant/README.md) - Smart home services and automation.

---

## **Prerequisites**
1. **Docker & Docker Compose** installed.
2. A **domain name** (optional, for dynamic DNS) or static public IP.
3. **Port forwarding** enabled on your router for UDP `51820` (VPN traffic).

---

## **1. create wg-easy directory (not for compose.yml)**
```bash
mkdir wg-easy
```

### **`compose.yml`**
```yaml
services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy
    container_name: wg-easy
    environment:
      - LANG=en
      - WG_HOST=mydomain.com  # Replace with your domain or public IP
      - PASSWORD_HASH=${WG_PASSWORD_HASH}  # From .env
      - PORT=51821            # Web UI port
      - WG_PORT=51820         # WireGuard VPN port
    volumes:
      - ./wg-easy:/etc/wireguard
    ports:
      - "51820:51820/udp"    # WireGuard traffic
      - "51821:51821/tcp"     # Web UI
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
      - net.ipv4.ip_forward=1
    restart: unless-stopped
```

### **`.env` File**
Create `.env` in the same folder with your **hashed password**:
```bash
# Generate with: openssl passwd -6 "yourpassword"
WG_PASSWORD_HASH="$2y$10$ABC123... (your hashed password)"
```

---

## **2. Start WG-Easy**
```bash
docker compose up -d
```

---

## **3. Router Configuration**
1. **Port Forwarding**:  
   - Forward UDP `51820` to your server’s local IP.  

2. **Dynamic DNS (Optional)**:  
   - If your public IP changes, use a DDNS service (e.g., Cloudflare API).

---

## **4. Access WG-Easy Web UI**
🔗 **`http://<your-server-ip>:51821`**  
- **Login**: Use the password from `.env`.  

---

## **5. Create VPN Clients**
1. **Add a Client**:  
   - Name: `phone` or `laptop`.  
   - Allowed IPs: `10.8.0.0/24` (default).  
   - DNS: Set to your AdGuard Home IP (e.g., `192.168.1.100`) (optional).  

2. **Download Config/QR Code**:  
   - Use the `.conf` file or scan the QR code in the WireGuard app.  
---

## **6. Connect Devices**
1. **Install WireGuard**:  
   - [Android](https://play.google.com/store/apps/details?id=com.wireguard.android)  
   - [iOS](https://apps.apple.com/app/wireguard/id1441195209)  
   - [Desktop](https://www.wireguard.com/install/)  

2. **Import Config**:  
   - Load the `.conf` file or scan the QR code.  

---

## **7. Verify Connectivity**
- **Check WG-Easy Dashboard**: Connected clients appear online.  
- **Test DNS**: Run `nslookup example.com` on a connected device to verify AdGuard Home is filtering.  