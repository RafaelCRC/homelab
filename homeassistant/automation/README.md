# Home Assistant Automations
This is a work in progress, check back for more!

## Navigation
* [Apps](/apps/README.md) - List of all the apps and services.
* [Dashboard](/dashboard/README.md) - Dashboards and monitoring tools.
* [Network](/network/README.md) - Network scripts and Cloudflare setup.
* [Home Assistant](/homeassistant/README.md) - Smart home services and automation.
  - [__Automation__](/homeassistant/automation/README.md)



# **Home Assistant + Proxmox Safe Shutdown Automation**

Automatically shut down a Proxmox server and cut power via a smart outlet, ensuring no data loss.

## **Prerequisites**
- Home Assistant (Docker/HA OS)
- Proxmox server with Wake-on-Power support
- Smart outlet (integrated with HA)

---

## **1. Create a Non-Root User on Proxmox**
Connect to Proxmox via SSH as `root` and run:
```bash
# Create a dedicated user
adduser ha-ssh
usermod -aG sudo ha-ssh  # Add to sudo group

# Allow passwordless shutdown and Proxmox commands
echo 'ha-ssh ALL=(ALL) NOPASSWD: /usr/sbin/shutdown, /usr/sbin/qm, /usr/sbin/pct' > /etc/sudoers.d/ha-ssh
chmod 440 /etc/sudoers.d/ha-ssh
```

---

## **2. Generate SSH Keys on Home Assistant Host**
On the machine running HA (Raspberry Pi/Docker host):
```bash
# Generate an Ed25519 key pair
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Copy the public key to Proxmox
ssh-copy-id -i ~/.ssh/id_ed25519 ha-ssh@<proxmox-ip>
```

---

## **3. Set Up SSH in Home Assistant**
### **Move Keys to HA’s Config Folder**
```bash
# On the HA host (replace with your HA config path)
mkdir -p /path/to/ha/config/.ssh
cp ~/.ssh/id_ed25519 /path/to/ha/config/.ssh/
chmod 600 /path/to/ha/config/.ssh/id_ed25519

# Add Proxmox to known_hosts
ssh-keyscan <proxmox-ip> >> /path/to/ha/config/.ssh/known_hosts
chmod 644 /path/to/ha/config/.ssh/known_hosts
```

### **Update `configuration.yaml`**
```yaml
shell_command:
  graceful_shutdown_proxmox: "ssh -o UserKnownHostsFile=/config/.ssh/known_hosts -i /config/.ssh/id_ed25519 ha-ssh@<proxmox-ip> 'sudo qm shutdown all && sudo pct shutdown all && sudo shutdown -h now'"
```

---

## **4. Add Ping Integration (UI)**
1. Go to **Settings > Devices & Services > Add Integration**.
2. Search for **"Ping (ICMP)"**.
3. Enter `<proxmox-ip>` and configure:
   - **Ping count**: `2`
   - **Consider home**: `60` (seconds)
4. This creates `binary_sensor.ping_<proxmox-ip>`.

---

## **5. Create the Automation**
### **Edit `automation.yaml`**
```yaml
- alias: "Safe Proxmox Shutdown with Outlet Control"
  mode: single
  trigger:
    - platform: event
      event_type: call_service
      event_data:
        service: script.safe_proxmox_shutdown
  action:
    # Step 1: Shut down Proxmox
    - service: shell_command.graceful_shutdown_proxmox

    # Step 2: Wait for Proxmox to go offline
    - wait_template: "{{ is_state('binary_sensor.ping_<proxmox-ip>', 'off') }}"
      timeout: "00:05:00"
      continue_on_timeout: false

    # Step 3: Turn off the outlet
    - service: switch.turn_off
      target:
        entity_id: switch.smart_outlet
```

---

## **6. Verification**
### **Test Components Individually**
1. **Ping Sensor**:  
   - Check `Developer Tools > States` for `binary_sensor.ping_<proxmox-ip>`.  
   - Manually shut down Proxmox and verify it flips to `off`.

2. **SSH Command**:  
   - Call `shell_command.graceful_shutdown_proxmox` in **Developer Tools > Services**.

3. **Outlet Control**:  
   - Test `switch.turn_off` with your outlet’s `entity_id`.


**✅ Done!** Your Proxmox server will now shut down gracefully, and the outlet will cut power only after confirmation.