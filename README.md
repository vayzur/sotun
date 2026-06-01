# SOTUN

minimal ssh tunnel manager.

sotun manages ssh tunnels as systemd services with automatic restart.
three tunnel types: socks5 proxy (`ssh -D`), reverse tunnel (`ssh -R`), local forward (`ssh -L`).

---

## how it works

you have two nodes:

- **exit node** — outside the restricted country. this is where you install sotun.
- **restricted node** — the one behind censorship (e.g. inside iran).

```
[restricted node] <- ssh reverse tunnel -> [exit node]
                                                │
                                           ssh -D (socks5)
                                           127.0.0.1:1080
```

the exit node opens a local socks5 proxy (`ssh -D`) and then pushes that port
to the restricted node over a reverse ssh tunnel (`ssh -R`).
apps on the restricted node use `127.0.0.1:1080` as a socks5 proxy.

> **note:** sotun is symmetric. either node can run the ssh process — whoever has
> better connectivity initiates. the noun (`tunnel` vs `forward`) describes what
> the tunnel *does*, not who runs it.

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

> **no internet on the restricted node?** run these two commands manually:
> ```bash
> sed -i 's/^#*AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config
> sed -i 's/^#*GatewayPorts.*/GatewayPorts clientspecified/' /etc/ssh/sshd_config
> systemctl restart sshd
> ```

this enables `AllowTcpForwarding` and `GatewayPorts` in sshd, then restarts it.
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

you will see output like:

```
[warn] important: add this public key to the authorized_keys on the remote node:

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... root@exit-node
```

**copy that public key** and add it to `~/.ssh/authorized_keys` on the restricted node:

```bash
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..." >> ~/.ssh/authorized_keys
```

> this is the only manual step. sotun uses key-based auth only, no passwords.

---

## step 4 — add a proxy

the proxy runs `ssh -D` on the exit node, creating a local socks5 listener.

```bash
sudo sotun proxy add 1080 root@127.0.0.1 22
```

arguments:
- `1080` — the port for the socks5 proxy **on this node** (must be 1024-65535)
- `root@127.0.0.1` — ssh user and host **on this (exit) node** — used for the `-D` tunnel
- `22` — the sshd port **on this (exit) node** (must be 1-65535)

> `127.0.0.1` here is intentional — the proxy connects back to localhost via ssh to create the socks5 tunnel.

---

## step 5 — add a tunnel

the tunnel runs `ssh -R` to push a port to the restricted node.

```bash
sudo sotun tunnel add 1080 root@203.0.113.10 22
```

arguments:
- `1080` — same port as the proxy above (must be 1024-65535)
- `root@203.0.113.10` — ssh user and ip of the **restricted node**
- `22` — sshd port on the **restricted node** (must be 1-65535)

after this, `127.0.0.1:1080` on the restricted node is a working socks5 proxy.

### custom addresses (advanced)

by default, both ends bind on `127.0.0.1`. to specify exact addresses use the full spec:

```
<laddr>:<lport>:<raddr>:<rport>
```

example — expose a vless/ws running on `0.0.0.0:443` of the exit node directly on the restricted node:

```bash
sudo sotun tunnel add 127.0.0.1:1080:0.0.0.0:443 root@203.0.113.10 22
```

this runs `ssh -R 127.0.0.1:1080:0.0.0.0:443` — the restricted node gets `127.0.0.1:1080`
which maps straight to the exit node's `0.0.0.0:443`.

---

## forward tunnels (ssh -L)

`sotun forward` pulls a port *from* the remote node to this node via `ssh -L`.
use this when the restricted node has better connectivity and initiates the connection,
or when you want to expose something on the remote side locally.

```bash
sudo sotun forward add 1080 root@203.0.113.10 22
```

this runs `ssh -L 127.0.0.1:1080:127.0.0.1:1080` — port 1080 on the remote node
is now accessible as `127.0.0.1:1080` on this node.

full spec works here too:

```bash
sudo sotun forward add 127.0.0.1:8080:127.0.0.1:80 root@203.0.113.10 22
```

> **tunnel vs forward:** `tunnel` pushes a port to the remote (`ssh -R`). `forward` pulls a port from the remote (`ssh -L`). both run `ssh` from this node.

---

## listing what you have

```bash
sudo sotun proxy list
sudo sotun tunnel list
sudo sotun forward list
```

example output:

```
proxies:
  port 1080    root@127.0.0.1:22  [active]

tunnels:
  -R 127.0.0.1:1080:127.0.0.1:1080    root@203.0.113.10:22  [active]

forwards:
  -L 127.0.0.1:8080:127.0.0.1:80      root@203.0.113.10:22  [active]
```

---

## start / stop / restart

```bash
sudo sotun proxy   start   1080
sudo sotun proxy   stop    1080
sudo sotun proxy   restart 1080

sudo sotun tunnel  start   1080
sudo sotun tunnel  stop    1080
sudo sotun tunnel  restart 1080

sudo sotun forward start   1080
sudo sotun forward stop    1080
sudo sotun forward restart 1080
```

---

## remove

```bash
sudo sotun tunnel  del 1080
sudo sotun forward del 1080
sudo sotun proxy   del 1080
```

this stops, disables, and deletes the service and config for that port.

---

## update

```bash
sudo sotun update
```

downloads and installs the latest version of sotun from github.

---

## uninstall

```bash
sudo sotun uninstall
```

stops and removes all proxies, tunnels, and forwards, deletes all services and config files,
and removes the `sotun` binary.

---

## port restrictions

- **listening port** (`<port>` or `<lport>`): must be **1024-65535** — this is the port that binds on this node
- **remote port** (`<rport>` in full spec): must be **1-65535** — it binds on the remote, any port is valid
- **ssh port** (`<ssh-port>`): must be **1-65535** — the sshd port on the remote host

---

## all commands

```
sotun init

sotun proxy add <port> <user@host> <ssh-port>
sotun proxy del <port>
sotun proxy list
sotun proxy start   <port>
sotun proxy stop    <port>
sotun proxy restart <port>

sotun tunnel add <spec> <user@host> <ssh-port>
sotun tunnel del <port>
sotun tunnel list
sotun tunnel start   <port>
sotun tunnel stop    <port>
sotun tunnel restart <port>

sotun forward add <spec> <user@host> <ssh-port>
sotun forward del <port>
sotun forward list
sotun forward start   <port>
sotun forward stop    <port>
sotun forward restart <port>

sotun update
sotun uninstall
sotun help
```

where `<spec>` is either `<port>` or `<laddr>:<lport>:<raddr>:<rport>`.

---

## full example walkthrough

**on the restricted node:**
```bash
# prepare sshd
bash <(curl -fsSL https://raw.githubusercontent.com/vayzur/sotun/main/prepare.sh)
```

**on the exit node:**
```bash
# install
curl -fsSL https://raw.githubusercontent.com/vayzur/sotun/main/install.sh | bash

# generate key and follow the instruction to copy it to restricted node
sudo sotun init

# add proxy (socks5 on this node via ssh -D)
sudo sotun proxy add 1080 root@127.0.0.1 22

# add reverse tunnel to restricted node
sudo sotun tunnel add 1080 root@<restricted-node-ip> 22
```

**on the restricted node, test it:**
```bash
curl --socks5 127.0.0.1:1080 ifconfig.io
```

---

## files

| path | description |
|---|---|
| `/usr/local/bin/sotun` | the helper binary |
| `/etc/sotun/proxy/<port>` | env config for each proxy |
| `/etc/sotun/tunnel/<port>` | env config for each tunnel |
| `/etc/sotun/forward/<port>` | env config for each forward |
| `/etc/systemd/system/proxy@.service` | systemd template for proxies |
| `/etc/systemd/system/tunnel@.service` | systemd template for tunnels |
| `/etc/systemd/system/forward@.service` | systemd template for forwards |
| `~/.ssh/id_ed25519_sotun` | dedicated ssh key |
