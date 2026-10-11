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
- **OP UDP Panel v2.6.0** → `/usr/local/bin/onepesewa` (alias `onepesewa` / `opudp`)
- Self-signed TLS certificate (RSA 4096) + tuned UDP kernel buffers
- Firewall + DNAT rules for the UDP port range (`6000-19999` → `5667`)
- Optional background monitors: pause/resume, IP limit, bandwidth, connection enforcement
- Optional **BBR + TCP optimizer** and **BadVPN UDP gateway**

The Telegram bot (`opudp_bot.py`) and the HWID enforcer are pulled in on demand from the panel.

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
