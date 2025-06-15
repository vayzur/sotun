# SOTUN

**High Performance Reverse SSH Tunnel Setup Automation**

Sotun is a automation tool to set up reverse SSH tunnels between an internal (e.g., censored) server and an external (e.g., uncensored) server. It's built for high performance networking, ideal for tunneling services like VPNs or web traffic through difficult environments.

---

## ⚙️ Requirements

### Tunnel Setup

You need two Linux-based servers:

* **Internal Server** (e.g., located in Iran or behind NAT/firewall)
* **External Server** (e.g., hosted in outside censorship)

### Sotun Runtime Requirements

* Python ≥ 3.11
* Ansible

If you're on **Windows**, use **WSL2** (Ubuntu preferred) as your Ansible controller.

---

## 🚀 Setup (Controller)

1. Clone the repo and enter the project directory.
2. Create a Python virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## 🗂️ Inventory Setup

Create your inventory file based on this sample:

```bash
cp inventory/sample.yml inventory/hosts.yml
vim inventory/hosts.yml
```

Example:

```yaml
all:
  hosts:
    internal_edge:
      ansible_host: edge1.example.com
    external_edge:
      ansible_host: edge2.example.com
  vars:
    ansible_user: root
    ansible_port: 22  # Change if you're using a non-standard SSH port
```

👉 **Best practice**: use custom SSH ports (not 22) to reduce bot scan attempts.

---

## 🔁 Reverse Tunnel Configuration

To forward specific ports from the internal server through the external server, edit:

```bash
vim inventory/group_vars/external_edge/tunnel.yml
```

Example:

```yaml
reverse_tunnel_ports:
  - 8080
  - 8880
  - 2052
```

This means these ports from `internal_edge` will be exposed on `external_edge`.

---

## 🛠️ Setup Tunnels

Once your inventory and tunnel ports are configured, deploy with:

```bash
ansible-playbook -i inventory/hosts.yml sotun.yml
```

If successful:

* Tunnels are active
* Services are systemd-based for resilience and autostart

---

## ✅ Verification

### On **Internal Edge**:

Check active reverse SSH connections:

```bash
ss -tulpn
```

### On **External Edge**:

Check each forwarded tunnel:

```bash
systemctl status sotun@8080.service
systemctl status sotun@8880.service
systemctl status sotun@2052.service
```

---

## 🌐 Using with a VPN

Sotun works great for tunneling a VPN server like **Xray-Core** or **3x-UI**.

### Steps:

1. Deploy tunnels via Sotun
2. Install the VPN software (e.g., Xray-core) on the **external server**
3. In your VPN config, replace `server address` with the **internal server IP**

   * Because it’s tunneled, the traffic hits the internal server via SSH tunnel

Example:

```
Client → Internal Edge (🇮🇷) ⇐ SSH Tunnel ⇒ External Edge (🇩🇪) → Internet
```

---

## 🧑‍💻 Contribution

Pull requests are welcome. You can:

* Add support for new distros
* Improve automation or fallback logic
* Add advanced SSH hardening options

> Please test before submitting and keep the code minimal and production-focused.

---

## 🧠 Notes & Best Practices

* This is for **reverse tunneling**, not general SSH proxying
* Reverse SSH tunnels are resilient against NAT, DPI, and firewalls
* Use SSH key authentication (avoid passwords in production)
* Consider using `autossh` or `systemd`-based reconnections (already handled in Sotun)
* Great for VPN tunneling inside censored environments

---

## ❓FAQ

**Q: Can I forward TCP + UDP?**
A: SSH tunnels only support TCP. For UDP-based VPNs like WireGuard, use `udptunnel` or `socat`.

**Q: Can I chain tunnels?**
A: Yes, but it adds complexity. Start simple.

**Q: Can I add more than one internal server?**
A: Not supported natively yet, but you can duplicate role logic or modify inventory layout.


---

## ❤️ Credits

Made with love for those who fight for a free, open internet.
