# 🚀 OPUDP Panel – ZIVPN Pro Multi-User UDP Tunnel Manager

**OPUDP** is a full-featured UDP tunnel management panel for the ZIVPN Android app. It allows you to host your own VPN server with **multi-user support**, **data quotas**, **expiry dates**, **device binding** (anti‑sharing), and a beautiful dashboard with geo‑IP location and real‑time system info.

> Maintained by [@OfficialOnePesewa](https://t.me/OfficialOnePesewa)

---

## ✨ Features

- ✅ **Single-file install** – everything in one script  
- ✅ **Multi-user database** – each user gets unique port, password, quota, expiry  
- ✅ **Data quota** – per‑user bandwidth limit (e.g., 1GB) enforced via iptables  
- ✅ **Expiry dates** – automatic cleanup of expired users  
- ✅ **Device binding** – prevent account sharing using Android Device ID  
- ✅ **Test users** – create temporary users for 1–60 minutes  
- ✅ **Live logs** – monitor each user’s connection in real time  
- ✅ **Backup & restore** – all user data can be saved and recovered  
- ✅ **Geo‑IP location** – shows server country, city, ISP in dashboard  
- ✅ **System date/time** – with timezone support  
- ✅ **Change port range** – default port is **5667** (standard ZIVPN port)  
- ✅ **Auto‑update** – update the panel with one menu option  
- ✅ **Uninstall** – completely remove everything if needed  

---

## 📱 Required Client App

Your users must install the **ZIVPN** app on Android:

👉 [Download ZIVPN from Google Play](https://play.google.com/store/apps/details?id=com.zivpn.android)

They will connect using:
- **Server IP** (your VPS public IP)
- **Port** (assigned to their account)
- **Password** (you provide)

---

## 🔒 Device Binding – Anti‑Sharing

To prevent one account from being used on multiple devices, you can bind a user to a **unique Device ID**.

### For the admin (you):
- Use menu option **21** in OPUDP to bind a Device ID to any user.

### For the user (they must):
1. Install **[Device Info](https://play.google.com/store/apps/details?id=com.unknownphone.devinfo)** from Google Play.  
2. Open the app → copy the **Device ID** (16 hex characters).  
3. Send the Device ID to you (admin).  

Once bound, only that specific device can use the account.

---

## 🖥️ Server Requirements

- **Ubuntu 20.04 / 22.04** (or any Debian‑based distro)  
- **Root access**  
- **Open port 5667+** (UDP) in your firewall  
- **1 CPU core, 512 MB RAM** (enough for 50+ users)  

---

## 📥 Installation

SSH into your server as **root** and run:

```bash
wget -O opudp.sh https://raw.githubusercontent.com/OfficialOnePesewa/opudp/main/opudp.sh
sudo chmod +x opudp.sh
sudo ./opudp.sh
