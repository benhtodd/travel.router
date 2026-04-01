# travel.router

A Raspberry Pi 5 configured as a portable travel router with local file storage, a public-facing event website, and secure remote access for a small team.

## What It Does

Plug the Pi into a hotel or venue network (wired or WiFi). It broadcasts a secured local WiFi network for your team (`advancedTE`), hosts an event website that anyone on that network can browse, and lets team members upload files (slides, documents) via a shared network drive. Remote access is always available via Tailscale regardless of location.

---

## Hardware

| Component | Details |
|-----------|---------|
| Device | Raspberry Pi 5 Model B — 8GB RAM |
| Hostname | `pinas01` |
| OS | Debian GNU/Linux 13 (Trixie) — 64-bit |
| Boot drive | 1.8TB NVMe (nvme0n1) — OS + Docker |
| Data drive | 3.6TB NVMe (nvme1n1) — mounted at `/mnt/data` |
| SD card | 58GB — unused |
| USB WiFi | Realtek RTL8811CU (802.11ac) — interface `wlan1` — team AP |

**Total usable storage:** ~5.4TB

### Network Interfaces

| Interface | Address | Role |
|-----------|---------|------|
| eth0 | DHCP (venue wired) | Wired uplink to venue network |
| wlan0 | DHCP (venue WiFi) | Wireless uplink — connects to hotel/venue WiFi |
| wlan1 | 192.168.10.1 | Team AP — broadcasts `advancedTE` network |
| tailscale0 | 100.92.121.12 | Tailnet — stable remote access IP |

---

## Services

All services run in Docker. Data is stored under `/mnt/data` on the 3.6TB data drive.

### WordPress — Public Event Site
- **Image:** `wordpress:latest` + `mariadb:10.11`
- **Port:** 80
- **URL:** `http://192.168.10.1` (team AP) or `http://100.92.121.12` (Tailscale)
- **Theme:** Neve
- **Admin:** `http://100.92.121.12/wp-admin` — user `vmware` / `VMware123!`
- **Compose:** `docker/wordpress/docker-compose.yml`
- **Data:** `/mnt/data/wordpress/`

The WordPress site is the public-facing event portal. Visitors browse without logging in. The front page displays an event calendar (Super Simple Event Calendar plugin). Each event links to a WordPress post that lists downloadable files directly from the event's slides folder using the `[event_files folder="..."]` shortcode.

**Plugins:**
- Super Simple Event Calendar — event listing on the front page
- Event Files Shortcode (mu-plugin) — renders file listings from `/mnt/data/files/slides/<folder>/`

**Apache config:** `docker/wordpress/slides.conf` — enables directory access for the slides volume mount.

### Samba — Team File Share
- **Image:** `dperson/samba:latest`
- **Ports:** 139, 445
- **Share path:** `\\<pi-ip>\files`
- **Credentials:** user `vmware`, password `VMware123`
- **Local path:** `/mnt/data/files/`
- **Compose:** `docker/samba/docker-compose.yml`

Team members map this as a network drive to upload slides and other files. Each event has a subfolder under `slides/` named `event.mm-dd-yy`.

> **Important:** New folders created under `/mnt/data/files/slides/` must be made world-writable before Samba can write to them:
> ```bash
> ssh pinas01-ts "sudo chmod -R 777 /mnt/data/files/slides/<folder>"
> ```

**Connecting:**

On the `advancedTE` team WiFi:
- Windows: `net use Z: \\192.168.10.1\files /user:vmware VMware123 /persistent:yes`
- Mac: `smb://192.168.10.1/files`

Via Tailscale (remote):
- Windows: `net use Z: \\100.92.121.12\files /user:vmware VMware123 /persistent:yes`
- Mac: `smb://100.92.121.12/files`

### Technitium DNS Server
- **Image:** `technitium/dns-server:latest`
- **Web UI:** `http://100.92.121.12:5380`
- **Admin:** user `admin` / `VMware123!`
- **Compose:** `docker/technitium/docker-compose.yml`

Handles DNS and DHCP for the local network. DHCP scope `advancedTE` serves `192.168.10.10–100` to clients on the team AP.

### WiFi AP — Team Network
- **Interface:** `wlan1` (USB Realtek RTL8811CU)
- **SSID:** `advancedTE`
- **Password:** `VMware123!`
- **Pi AP IP:** `192.168.10.1`
- **Client range:** `192.168.10.10–100` (via Technitium DHCP)
- **Upstream:** `wlan0` connects to venue WiFi; iptables NAT routes AP traffic out

AP is managed by NetworkManager (connection name `AP-wlan1`). iptables rules are persisted via `iptables-persistent`.

### Nginx — Static Portal (Retired)
- **Compose:** `docker/nginx/docker-compose.yml`
- **Status:** Stopped — replaced by WordPress

---

## Remote Access

All remote access uses **Tailscale**. The Pi's Tailscale IP (`100.92.121.12`) is stable regardless of which venue network it's on.

| Service | Tailscale URL |
|---------|--------------|
| WordPress site | `http://100.92.121.12` |
| WordPress admin | `http://100.92.121.12/wp-admin` |
| Technitium DNS | `http://100.92.121.12:5380` |
| Samba file share | `\\100.92.121.12\files` |
| SSH | `ssh pinas01-ts` |

> SSH aliases in `~/.ssh/config`:
> - `pinas01` — local LAN (10.0.0.141)
> - `pinas01-ts` — Tailscale (100.92.121.12) — use this when away from local LAN

---

## At a New Venue

1. Plug Pi into venue ethernet (eth0 gets DHCP automatically) **or** connect `wlan0` to venue WiFi via SSH
2. Tailscale comes up automatically once there's internet
3. SSH in: `ssh pinas01-ts`
4. Team connects to `advancedTE` WiFi — gets IP in `192.168.10.x`, routes through venue uplink

To connect `wlan0` to a new WiFi network:
```bash
ssh pinas01-ts "sudo nmcli dev wifi connect 'SSID' password 'password' ifname wlan0"
```

---

## Setting Up a New Event

1. Create a calendar entry in WordPress (`ssec_event` post type) with start date as post date
2. Create a WordPress post with `[event_files folder="event.mm-dd-yy"]` as the content
3. Update the calendar entry content to include the event name, date range, and a link to the post
4. Create the Samba folder: `ssh pinas01-ts "mkdir -p /mnt/data/files/slides/event.mm-dd-yy"`
5. Fix permissions: `ssh pinas01-ts "sudo chmod -R 777 /mnt/data/files/slides/event.mm-dd-yy"`

---

## Repository Structure

```
travel.router/
├── CLAUDE.md                           # Claude Code project instructions
├── README.md                           # This file
├── .gitignore
├── docker/
│   ├── wordpress/
│   │   ├── docker-compose.yml          # WordPress + MariaDB
│   │   ├── slides.conf                 # Apache config — enables slides directory access
│   │   ├── slides-header.html          # FancyIndex header (reference only)
│   │   └── slides-footer.html          # FancyIndex footer (reference only)
│   ├── samba/
│   │   ├── docker-compose.yml          # Samba file share
│   │   └── smb.conf                    # Samba share configuration
│   ├── technitium/
│   │   └── docker-compose.yml          # Technitium DNS/DHCP
│   └── nginx/
│       ├── docker-compose.yml          # Static portal (retired)
│       └── nginx.conf
├── config/                             # System config files (hostapd, etc.) — pending
├── scripts/
│   ├── setup.sh                        # Initial Pi provisioning
│   └── setup-technitium.sh             # Technitium post-deploy setup
└── docs/
    └── assets.md                       # Hardware and infrastructure inventory
```

---

## Deploying to the Pi

Each service has its own `docker-compose.yml`. After making changes locally, copy the files to the Pi and restart:

```bash
scp docker/wordpress/docker-compose.yml docker/wordpress/slides.conf pinas01-ts:/home/todd/docker/wordpress/
ssh pinas01-ts "cd /home/todd/docker/wordpress && docker compose up -d"
```

All Docker Compose files live on the Pi at `/home/todd/docker/<service>/`.

---

## Data Layout on Pi

```
/mnt/data/
├── files/                          # Samba share root
│   └── slides/                     # Event folders — uploaded via Samba, served via WordPress
│       ├── orlando.04-20-26/
│       ├── clearwater.05-04-26/
│       └── amsterdam.06-22-26/
├── wordpress/
│   ├── site/                       # WordPress files (plugins, themes, uploads, mu-plugins)
│   └── db/                         # MariaDB data
├── technitium/
│   └── config/                     # Technitium DNS/DHCP config (persisted)
└── delivery-web/                   # Legacy static site directory (unused)
```

---

## Pending

- [ ] Build out WordPress site content (speakers pages, etc.)
