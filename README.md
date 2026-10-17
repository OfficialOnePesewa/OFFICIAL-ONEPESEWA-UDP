# OFFICIAL ONEPESEWA UDP

One-command installer for the **OP UDP VPS Panel** + **ZIVPN UDP server**.
Maintained by [@OfficialOnePesewa](https://t.me/officialonepesewatech).

---

## ⚡ Install (one line)

Copy and run this on a fresh **Debian / Ubuntu** VPS:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/OfficialOnePesewa/OFFICIAL-ONEPESEWA-UDP/main/install.sh)
```

If you are **not** logged in as root, use:

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/OfficialOnePesewa/OFFICIAL-ONEPESEWA-UDP/main/install.sh)
```

That's it — the installer downloads everything and sets it up. Open the panel afterwards with:

```bash
onepesewa      # or the short alias:  opudp
```

---

## What it installs

- **ZIVPN v1.4.9** UDP server → `/usr/local/bin/zivpn` (systemd service `zivpn`)
- **OP UDP Panel v2.7.1** → `/usr/local/bin/onepesewa` (alias `onepesewa` / `opudp`)
- Self-signed TLS certificate (RSA 4096) + tuned UDP kernel buffers
- Firewall + DNAT rules for the UDP port range (`6000-19999` → `5667`)
- Optional background monitors: pause/resume, IP limit, bandwidth, connection enforcement
- Optional **BBR + TCP optimizer** and **BadVPN UDP gateway**

The Telegram bot (`opudp_bot.py`) and the HWID enforcer are pulled in on demand from the panel.

### Extra protocols (`Panel → VPN Protocols`)

Installable from inside the panel, and designed to coexist with ZIVPN:

- **HTTP-Custom (udp-custom)** — listens on `udp/36712`, with port-hopping DNAT covering `1-5999` and `20000-65535`. ZIVPN's own `6000-19999` band and `5667`/`7300` are deliberately excluded, so neither protocol shadows the other. The tunnel exclude list (`53`,`5300`,`5667`,`5060`,`7300` by default) is editable from the panel and is re-applied along with the DNAT. udp-custom authenticates against the system account database (`/etc/shadow`), so the panel provisions a matching **system account for every user** automatically (create, renew, pause/resume, remove, cleanup and install-time migration). The HTTP-Custom username is `u` followed by the first 10 hex digits of the MD5 of the account password (e.g. `u9f8a2b1c3d`) and the password is the same one the panel shows; both are printed in the create-user, trial and bot messages. Pausing a user locks the account and removing a user deletes it, so HTTP-Custom access always mirrors the panel database.
- **BadVPN UDPGW** — `udp/7300`, taking over that port from ZIVPN's DNAT (restored on uninstall).
- **WS-SSH** — WebSocket-to-SSH bridge on `tcp/2082`.

Each protocol gets a port pre-flight before install, and uninstalling removes its services, DNAT/RETURN rules, open firewall ports, and (for HTTP-Custom) the provisioned user accounts.

---

## Requirements

- Debian 10+ or Ubuntu 20.04+
- Root (or a user with `sudo`)
- Architecture: `x86_64`/`amd64` or `aarch64`/`arm64`
- Internet access

---

## Panel features

- **Service control** — start / stop / restart / status
- **User management** — list, add, remove, renew, cleanup expired, trial users
- Per-user **password**, **expiry**, **data quota**, **HWID lock**, **IP limit**, **connection limit**
- **Pause / resume** accounts with a timer
- **Monitoring** — connection stats, bandwidth + expiry, live logs, speed test
- **System & tools** — backup/restore, port range, panel update, Telegram bot config
- Fire ASCII logo with live geo-location and system info

---

## Repository layout

| File | Purpose |
|------|---------|
| `install.sh` | One-line installer (downloads and sets up everything) |
| `onepesewa` | Management panel (installed to `/usr/local/bin`) |
| `opudp_bot.py` | Telegram bot |
| `bin/opudp_hwid_enforcer.sh` | HWID lock enforcer |
| `config/badvpn-udpgw.service` | BadVPN UDP gateway service |

---

## Updating

From inside the panel choose **System & Tools → Update Panel**, or re-run the one-line installer.

---

## Links

- Admin: [@OfficialOnePesewa](https://t.me/officialonepesewatech)
- Channel: https://t.me/officialonepesewatech

> Disclaimer: install and use only on servers you own or are authorized to manage.
