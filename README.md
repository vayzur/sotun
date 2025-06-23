# SOTUN

**High Performance SSH Tunnel Setup Automation**

Sotun is an automation tool to set up SSH tunnels between internal (e.g., censored) and external (e.g., uncensored) Linux servers. It's built for high performance networking and low-latency environments, ideal for tunneling services like VPNs or web traffic through firewalled infrastructure.

---

## ⚙️ Requirements

### Tunnel Setup

You need two (or more) Linux-based servers:

* **Client Node** (typically inside censorship/NAT)
* **Server Node** (typically outside censorship)

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
````

---

## 🗂️ Inventory Setup

Create your inventory file based on this sample:

```bash
cp -r inventory/sample inventory/hosts
vim inventory/hosts/hosts.yml
```

Example:

```yaml
all:
  hosts:
    node1:
      ansible_host: edge1.example.com
    node2:
      ansible_host: edge2.example.com
  vars:
    ansible_user: root
    ansible_port: 22  # Change if you're using a non-standard SSH port
```

👉 **Best practice**: use non-default SSH ports (not 22) to reduce bot scan attempts.

---

## 🔧 Tunnel Configuration

Sotun now supports a declarative, flexible DSL format:

```bash
vim inventory/group_vars/all/tunnels.yml
```

Example:

```yaml
tunnels:
  - name: tun2052
    mode: L
    client_node: node1
    server_node: node2
    local_host: 0.0.0.0
    local_port: 2052
    remote_host: 127.0.0.1
    remote_port: 2052

  - name: tun8880
    mode: R
    client_node: node2
    server_node: node1
    local_host: 0.0.0.0
    local_port: 8880
    remote_host: 127.0.0.1
    remote_port: 8880
```

---

## 🛠️ Deploy

Once your inventory and tunnel config are ready, deploy with:

```bash
ansible-playbook -i inventory/hosts/hosts.yml sotun.yml
```

Sotun will:

* Install required packages
* Create the `sotun` user
* Distribute SSH keys and configs
* Create and enable `systemd` services for each tunnel

---

## ✅ Verification

### Check services:

```bash
systemctl status sotun@tun8080.service
systemctl status sotun@tun8880.service
```

### Check open ports:

```bash
ss -tulnp | grep 2052
```

---

## 🌐 Using with a VPN

Sotun works great for tunneling a VPN server like **Xray-Core** or **3x-UI**.

### Steps:

1. Deploy tunnels via Sotun
2. Install the VPN software (e.g., Xray-core) on the **server node**
3. In your VPN config, replace `server address` with the **client node IP**

   * Traffic will reach the internal/censored node through the tunnel

Example:

```
Client → Node1 (🇮🇷) ⇐ SSH Tunnel ⇒ Node2 (🇩🇪) → Internet
```

---

## 🧑‍💻 Contribution

Pull requests are welcome. You can:

* Add support for new distros
* Improve automation or fallback logic
* Add SSH hardening or autossh-style features

> Please keep the code minimal and production-grade.

---

## 🧠 Notes & Best Practices

* Sotun supports both **reverse** (`-R`) and **forward** (`-L`) tunnels
* SSH tunnels are TCP-only
* Avoid using ports < 1024 unless you configure privileges properly
* SSH keys are auto-generated once and distributed to all nodes
* Tunnels are managed via systemd, using real-time priorities

---

## ❓FAQ

**Q: Can I forward TCP + UDP?**
A: SSH only supports TCP. For UDP-based protocols (like WireGuard), consider `udptunnel` or `socat`.

**Q: Can I chain tunnels?**
A: Yes, but keep it simple unless necessary.

**Q: Can I use more than two nodes?**
A: Yes. You can define as many tunnels as you want, with any combination of client/server nodes.

---

## ❤️ Credits

Made with love for those who fight for a free, open internet.
