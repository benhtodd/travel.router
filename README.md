# travel.router

A Raspberry Pi 5 configured as a portable travel router with local file storage, a public-facing event website, and secure remote access for a small team.

## What It Does

Plug the Pi into a hotel or venue network. It shares a secured local WiFi network for your team, hosts an event website that anyone on that network can browse, and lets team members upload files (slides, documents) via a shared network drive. Remote access is always available via Tailscale regardless of location.

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

**Total usable storage:** ~5.4TB

### Network Interfaces

| Interface | Address | Role |
|-----------|---------|------|
| eth0 | 10.0.0.140 | Wired LAN (connects to venue network) |
| wlan0 | 10.0.0.141 | Onboard WiFi (future: local AP) |
| tailscale0 | 100.92.121.12 | Tailnet — stable remote access IP |

> **Note:** A USB WiFi adapter is needed for full travel router mode (AP + upstream client simultaneously on separate radios). The onboard WiFi cannot do both at once.

---

## Services

All services run in Docker. Data is stored under `/mnt/data` on the 3.6TB data drive.

### WordPress — Public Event Site
- **Image:** `wordpress:latest` + `mariadb:10.11`
- **Port:** 80
- **URL:** `http://<pi-local-ip>` (local) or `http://100.92.121.12` (Tailscale)
- **Theme:** Neve
- **Admin:** `http://100.92.121.12/wp-admin` — user `vmware`
- **Compose:** `docker/wordpress/docker-compose.yml`
- **Data:** `/mnt/data/wordpress/`

The WordPress site is the public-facing event portal. Visitors browse without logging in. Content includes event schedule, speaker info, and download links to slides. The site design can be adjusted per event using WordPress themes and customizer — previous content is preserved in the database between events.

### Samba — Team File Share
- **Image:** `dperson/samba:latest`
- **Ports:** 139, 445
- **Share path:** `\\<pi-ip>\files`
- **Credentials:** user `vmware`, password `VMware1234`
- **Local path:** `/mnt/data/files/`
- **Compose:** `docker/samba/docker-compose.yml`

Team members map this as a network drive to upload slides and other files. The `slides` subfolder (`/mnt/data/files/slides/`) is linked directly from the WordPress site.

**Connecting:**
- Windows: `net use Z: \\100.92.121.12\files /user:vmware VMware1234 /persistent:yes`
- Mac: `smb://100.92.121.12/files`

### Technitium DNS Server
- **Image:** `technitium/dns-server:latest`
- **Web UI:** `http://100.92.121.12:5380`
- **Compose:** `docker/technitium/docker-compose.yml`

Handles DNS and DHCP for the local network. Provides local name resolution and network management via a web UI.

### Nginx — Static Portal (Retired)
- **Compose:** `docker/nginx/docker-compose.yml`
- **Status:** Stopped — replaced by WordPress

Kept for reference. Previously served a static HTML site from a GitHub-synced directory. WordPress now handles the public portal.

---

## Remote Access

All remote access uses **Tailscale**. The Pi's Tailscale IP (`100.92.121.12`) is stable regardless of which venue network it's on.

| Service | Tailscale URL |
|---------|--------------|
| WordPress site | `http://100.92.121.12` |
| WordPress admin | `http://100.92.121.12/wp-admin` |
| Technitium DNS | `http://100.92.121.12:5380` |
| Samba file share | `\\100.92.121.12\files` |
| SSH | `ssh pinas01` |

---

## Repository Structure

```
travel.router/
├── CLAUDE.md                       # Claude Code project instructions
├── README.md                       # This file
├── .gitignore
├── docker/
│   ├── wordpress/
│   │   └── docker-compose.yml      # WordPress + MariaDB
│   ├── samba/
│   │   ├── docker-compose.yml      # Samba file share
│   │   └── smb.conf                # Samba share configuration
│   ├── technitium/
│   │   └── docker-compose.yml      # Technitium DNS/DHCP
│   └── nginx/
│       ├── docker-compose.yml      # Static portal (retired)
│       └── nginx.conf
├── config/                         # System config files (hostapd, etc.) — pending
├── scripts/
│   ├── setup.sh                    # Initial Pi provisioning
│   └── setup-technitium.sh         # Technitium post-deploy setup
└── docs/
    └── assets.md                   # Hardware and infrastructure inventory
```

---

## Deploying to the Pi

Each service has its own `docker-compose.yml`. After making changes locally, copy the file to the Pi and restart the service:

```bash
# Example: update WordPress
scp docker/wordpress/docker-compose.yml pinas01:/home/todd/docker/wordpress/
ssh pinas01 "cd /home/todd/docker/wordpress && docker compose up -d"
```

All Docker Compose files live on the Pi at `/home/todd/docker/<service>/`.

---

## Data Layout on Pi

```
/mnt/data/
├── files/                  # Samba share root
│   └── slides/             # Slides — linked from WordPress
├── wordpress/
│   ├── site/               # WordPress files (plugins, themes, uploads)
│   └── db/                 # MariaDB data
└── delivery-web/           # Legacy static site directory (unused)
```

---

## Pending

- [ ] USB WiFi adapter — required for travel AP mode (dual radio)
- [ ] Configure `hostapd` for local WiFi AP broadcasting
- [ ] Configure `iptables` for NAT/routing (venue network → local AP)
- [ ] Build out WordPress site content (schedule, speakers, downloads pages)
