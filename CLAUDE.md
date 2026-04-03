# travel.router

## What This Project Is

A Raspberry Pi 5 configured as a portable travel router with secure local storage, a public-facing event website, and secure remote access for a small team.

**Hardware:**
- Raspberry Pi 5 8GB (pinas01)
- 2x NVMe drives — 1.8TB (OS, boot) + 3.6TB (data, mounted at `/mnt/data`)
- USB WiFi adapter — Realtek RTL8811CU (wlan1) — team AP

**Core capabilities:**
1. **Travel router** — connects to hotel/venue WiFi upstream (eth0 or wlan0), shares a secured local network via wlan1 (`advancedTE` SSID)
2. **Event WordPress site** — attendees on the AP browse `http://pine.local` (Technitium resolves it)
3. **Team file share** — Samba on `/mnt/data/files/`, team uploads slides via `\\<pi-ip>\files`
4. **Remote access** — Tailscale always-on at `100.92.121.12` regardless of venue

---

## Network Interfaces

| Interface | Address | Role |
|-----------|---------|------|
| eth0 | DHCP (venue wired) | Wired uplink to venue network |
| wlan0 | DHCP (venue WiFi) | Wireless uplink — connects to hotel/venue WiFi |
| wlan1 | 192.168.10.1 | Team AP — broadcasts `advancedTE` network |
| tailscale0 | 100.92.121.12 | Tailnet — stable remote access IP |

---

## Stack

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| WordPress | `wordpress:latest` + `mariadb:10.11` | 80 | Public event site |
| Samba | `dperson/samba:latest` | 139, 445 | Team file share |
| Technitium | `technitium/dns-server:latest` | 5380, 53, 67 | DNS + DHCP for AP clients |

All services run in Docker. Data lives under `/mnt/data/`.
Compose files on the Pi: `/home/todd/docker/<service>/docker-compose.yml`

---

## Service Access

| Service | AP network | Tailscale (remote) |
|---------|-----------|-------------------|
| WordPress | http://pine.local or http://192.168.10.1 | http://100.92.121.12 |
| WordPress admin | http://pine.local/wp-admin | http://100.92.121.12/wp-admin |
| Technitium | http://192.168.10.1:5380 | http://100.92.121.12:5380 |
| Samba | \\192.168.10.1\files | \\100.92.121.12\files |
| SSH | — | `ssh pinas01` (via ~/.ssh/config + todd-ssh-key) |

---

## Credentials

| Service | User | Password |
|---------|------|----------|
| WordPress admin | vmware | VMware123! |
| Technitium admin | admin | VMware123! |
| Samba | vmware | VMware1234 |
| Pi SSH | todd | (todd-ssh-key from 1Password) |

---

## Technitium DNS — Important Notes

- **Volume mount:** `/mnt/data/technitium/config:/etc/dns` — maps the FULL `/etc/dns` directory
  - ⚠️ Previous mistake was mapping to `/etc/dns/config` (a subdirectory) — config was NOT persisting
  - Fixed 2026-04-03: correct mount is `:/etc/dns`, all config now survives container recreates
- **DHCP scope:** `advancedTE` — serves `192.168.10.10–100` to AP clients
- **DNS zone:** `pine.local` → `192.168.10.1` — attendees on `advancedTE` reach WordPress at `http://pine.local`
- **Password reset:** `DNS_SERVER_ADMIN_PASSWORD` env var only applies on first run (fresh config). If password is lost, copy config out, recreate container, copy back.

---

## WordPress — Key Info

- **Site URL:** `http://192.168.10.1` (matches the AP IP — do NOT change to pine.local or 100.92.121.12)
- **Theme:** Neve
- **Plugins:** Super Simple Event Calendar, Event Files Shortcode (mu-plugin)
- **Slides served from:** `/mnt/data/files/slides/<event-folder>/` via `[event_files folder="..."]` shortcode
- **Data path:** `/mnt/data/wordpress/` (site files + MariaDB)

---

## Samba File Share

- **Share path:** `\\<pi-ip>\files` → `/mnt/data/files/`
- **Event slides:** `/mnt/data/files/slides/<event-folder>/`
- ⚠️ New event folders need world-writable permissions for Samba to write:
  ```bash
  ssh pinas01 "sudo chmod -R 777 /mnt/data/files/slides/<folder>"
  ```

---

## SSH Aliases (~/.ssh/config)

```bash
ssh pinas01      # 10.0.0.140 (local LAN, wired)
ssh pinas01-ts   # 100.92.121.12 (Tailscale — use when away from local LAN)
```

---

## Setting Up a New Event

1. Create calendar entry in WordPress (`ssec_event` post type)
2. Create a WordPress post with `[event_files folder="event.mm-dd-yy"]`
3. Link calendar entry to the post
4. Create Samba folder: `ssh pinas01 "mkdir -p /mnt/data/files/slides/event.mm-dd-yy"`
5. Fix permissions: `ssh pinas01 "sudo chmod -R 777 /mnt/data/files/slides/event.mm-dd-yy"`

---

## At a New Venue

1. Plug Pi into venue ethernet (eth0 gets DHCP automatically), or connect wlan0 to venue WiFi:
   ```bash
   ssh pinas01-ts "sudo nmcli dev wifi connect 'SSID' password 'password' ifname wlan0"
   ```
2. Tailscale comes up automatically once internet is available
3. Team connects to `advancedTE` WiFi → gets `192.168.10.x` IP + Pi as DNS
4. Attendees browse `http://pine.local` → WordPress

---

## Data Layout on Pi

```
/mnt/data/
├── files/                      # Samba share root
│   └── slides/                 # Event folders — uploaded via Samba, served by WordPress
│       ├── orlando.04-20-26/
│       └── clearwater.05-04-26/
├── wordpress/
│   ├── site/                   # WordPress files (plugins, themes, mu-plugins)
│   └── db/                     # MariaDB data
└── technitium/
    └── config/                 # Technitium DNS/DHCP config — PERSISTED (mapped to /etc/dns)
```

---

## Pending

- [ ] Build out WordPress site content (speakers pages, schedule, etc.)
- [ ] Configure hostapd for travel AP mode (wlan1)
- [ ] Decide on USB WiFi adapter strategy
