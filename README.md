# SOTUN

minimal ssh tunnel manager.

sotun manages ssh tunnels as systemd services with automatic restart.
four tunnel types: socks5 proxy (`ssh -D`), reverse tunnel (`ssh -R` / push), local forward (`ssh -L`), and L3 tunnel (`ssh -w`).

---

## how it works

you have two nodes:

- **exit node** — outside the restricted country. this is where you install sotun.
- **restricted node** — the one behind censorship (e.g. inside iran).

---

## requirements

- linux with systemd
- openssh client (`ssh`)
- `curl` (for install and update)

---

## step 1 — prepare the restricted node

run this on the **restricted node** (the one inside iran, etc.):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/vayzur/sotun/main/prepare.sh)
```

> **no internet on the restricted node?** run these commands manually:
> ```bash
> sed -i 's/^#*AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config
> sed -i 's/^#*GatewayPorts.*/GatewayPorts clientspecified/' /etc/ssh/sshd_config
> sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 3/' /etc/ssh/sshd_config
> sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 3/' /etc/ssh/sshd_config
> sed -i 's/^#*PermitTunnel.*/PermitTunnel yes/' /etc/ssh/sshd_config
> systemctl restart sshd
> ```

this enables `AllowTcpForwarding`, `GatewayPorts`, `PermitTunnel`, and SSH keepalives in sshd, then restarts it.
you only do this once.

---

## step 2 — install sotun on the exit node

run this on the **exit node** (the one outside iran):

```bash
curl -fsSL https://raw.githubusercontent.com/vayzur/sotun/main/install.sh | bash
```

---

## step 3 — init (generate ssh key)

on the **exit node**, run:

```bash
sudo sotun init
```

this generates a dedicated ssh key at `~/.ssh/id_ed25519_sotun` and prints the public key.

**copy that public key** and add it to `~/.ssh/authorized_keys` on the restricted node:

```bash
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..." >> ~/.ssh/authorized_keys
```

---

## step 4 — add a proxy

the proxy runs `ssh -D` on the exit node, creating a local socks5 listener.

```bash
sudo sotun proxy add 1080 root@127.0.0.1 22
```

---

## step 5 — push (reverse ssh tunnel)

the push runs `ssh -R` to push a port to the restricted node.

```bash
sudo sotun push add 1080 root@203.0.113.10 22
```

sotun assigns a name automatically (`p0`, `p1`, ...). you use this name for all
subsequent operations on that push.

---

## step 6 — tunnel (L3 ssh tunnel)

the tunnel runs `ssh -w` to create a virtual network interface between nodes.

```bash
sudo sotun tunnel add 0 0 10.0.0.1 10.0.0.2 root@203.0.113.10 22
```

arguments:
- `0` — local tunnel id (tun0)
- `0` — remote tunnel id (tun0)
- `10.0.0.1` — local tunnel ip
- `10.0.0.2` — remote tunnel ip
- `root@203.0.113.10` — restricted node ssh user/ip
- `22` — sshd port on restricted node

sotun assigns a name automatically (`t0`, `t1`, ...).

---

## forward tunnels (ssh -L)

`sotun forward` pulls a port *from* the remote node to this node via `ssh -L`.

```bash
sudo sotun forward add 1080 root@203.0.113.10 22
```

---

## listing what you have

```bash
sudo sotun proxy list
sudo sotun push list
sudo sotun tunnel list
sudo sotun forward list
```

---

## start / stop / restart

```bash
sudo sotun push start p0
sudo sotun tunnel start t0
```

---

## remove

```bash
sudo sotun push del p0
sudo sotun tunnel del t0
```

---

## all commands

```
sotun init

sotun proxy add <port> <user@host> <ssh-port>
sotun proxy del <port>
sotun proxy list

sotun push add <spec> <user@host> <ssh-port> [name]
sotun push del <name>
sotun push list

sotun tunnel add <local_id> <remote_id> <local_ip> <remote_ip> <user@host> <ssh-port> [name]
sotun tunnel del <name>
sotun tunnel list

sotun forward add <spec> <user@host> <ssh-port> [name]
sotun forward del <name>
sotun forward list

sotun update
sotun uninstall
sotun help
```

where `<spec>` is either `<port>` or `<laddr>:<lport>:<raddr>:<rport>`.
