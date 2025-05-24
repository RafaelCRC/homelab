# **Webmin**

Webmin is a web-based system administration tool for Unix-like systems. This guide covers the installation and basic configuration of Webmin on a Debian/Ubuntu system.

![alt text](/assets/network/cloudflare_script.png)

## Navigation
* [Apps](/apps/README.md) - List of all the apps and services.
* [Dashboard](/dashboard/README.md) - Dashboards and monitoring tools.
* [Network](/network/README.md) - Network scripts and Cloudflare setup.
* [Home Assistant](/homeassistant/README.md) - Smart home services and automation.
* [Server Monitoring](/monitoring/README.md) - Server Monitoring services.
  - [__Webmin__](/monitoring/webmin/README.md) - Webmin server monitoring for PI.

# **Webmin Setup Documentation**

## **Prerequisites**
- A server running Debian, Ubuntu, or a derivative
- Root or sudo access
- Internet connection

---

## **Installation Steps**

### **1. Run the Webmin Setup Script**
Execute the following commands to install Webmin:

```bash
# Download the setup script
curl -o webmin-setup-repo.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh

# Make the script executable
chmod +x webmin-setup-repo.sh

# Run the setup script
sudo sh webmin-setup-repo.sh

# Install Webmin with recommended packages
sudo apt-get install webmin --install-recommends
```

### **2. Access Webmin**
After installation completes:
1. Open your browser and navigate to:
   ```
   https://your-server-ip:10000
   ```
2. Log in with your **root** or **sudo user** credentials.

---

## **Post-Installation Configuration**

### **1. Firewall Configuration**
If you're using a firewall (e.g., `ufw`), allow Webmin's port:
```bash
sudo ufw allow 10000/tcp
```

### **2. Secure Webmin**
- Change the default port (optional):
  ```bash
  sudo nano /etc/webmin/miniserv.conf
  ```
  Modify the `port=` line to your desired port (e.g., `port=10443`).

---

## **Basic Usage**
### **1. Dashboard Overview**
- **System Information**: View CPU, memory, and disk usage.
- **User Management**: Create and manage system users.
- **Software Packages**: Install/remove packages via the web interface.

### **2. Common Modules**
- **Apache/NGINX**: Web server configuration.
- **Postfix/Dovecot**: Email server setup.
- **Cron Jobs**: Schedule tasks.
- **File Manager**: Browse and edit files.

---

## **Uninstallation**
To completely remove Webmin:
```bash
sudo apt-get purge webmin
sudo rm -rf /etc/webmin
```
