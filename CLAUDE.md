# travel.router

## What This Project Is

A Raspberry Pi configured as a portable travel router with secure local storage and remote access for a small team.

**Hardware:**
- Raspberry Pi 5 8GB (pinas01)
- 2x NVMe drives — 1.8TB (OS) + 3.6TB (data, mounted at `/mnt/data`)

**Core capabilities:**
1. **Travel router** — connects to hotel/venue WiFi upstream, shares a secured local network
2. **Tailscale integration** — joins the tailnet so all devices stay connected regardless of location
3. **Secure file storage** — files stored on the NVMe drives, not in the cloud
4. **Team remote access** — team members can access shared files remotely via Tailscale

## Stack

- **OS**: Debian 13 (Trixie) — 64-bit
- **Networking**: hostapd (WiFi AP), iptables (routing/NAT) — pending
- **DNS/DHCP**: Technitium DNS Server (Docker) — web UI on port 5380
- **VPN/mesh**: Tailscale — Pi is at 100.92.121.12
- **File sharing (team)**: Samba (Docker) — mounts as `\\100.92.121.12\files`, user: vmware/VMware1234
- **Public portal**: WordPress (Docker) — port 80, Neve theme, admin: vmware/VMware123!
- **Container runtime**: Docker + Docker Compose
- **Secrets**: 1Password CLI on the dev machine

## Project Structure

```
travel.router/
├── CLAUDE.md               # This file
├── .gitignore
├── docker/                 # Docker Compose services
│   ├── wordpress/          # WordPress + MariaDB (port 80)
│   ├── samba/              # Team file share (ports 139/445)
│   ├── technitium/         # DNS/DHCP (port 5380)
│   └── nginx/              # Static portal (retired — kept for reference)
├── config/                 # Service config files (hostapd, etc.)
├── scripts/                # Setup and maintenance scripts
│   └── setup.sh            # Initial Pi provisioning
│   └── setup-technitium.sh
└── docs/                   # Architecture decisions, network diagrams, notes
```

## Claude Code Setup

This project uses **OpenRouter free tier** to save Claude Pro credits during development.
- Config: `.claude/settings.local.json` (git-ignored)
- Credential resolved at startup via `.claude/get-token.sh` (calls 1Password)
- If the model feels slow/limited, switch to `cs` or `cr` alias from `~/` to use Claude Pro

## Key Decisions & Working Notes

- [x] OS: Debian 13 (Trixie) — already installed on pinas01
- [x] DNS/DHCP: Technitium DNS Server in Docker
- [x] Team file uploads: Samba (Docker, port mapping)
- [x] Public portal: WordPress + MariaDB (Docker, port 80), Neve theme
- [x] Portal GitHub sync dropped — WordPress manages content directly
- [x] Slides folder: `/mnt/data/files/slides` — accessible via Samba and linked from WordPress
- [ ] Build out WordPress site (schedule, speakers, downloads pages)
- [ ] Decide on WiFi adapter strategy for travel AP mode (USB adapter recommended)
- [ ] Configure hostapd for travel AP mode
