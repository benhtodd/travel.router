# travel.router

## What This Project Is

A Raspberry Pi configured as a portable travel router with secure local storage and remote access for a small team.

**Hardware:**
- Raspberry Pi (model TBD)
- 2x NVMe drives for local storage

**Core capabilities:**
1. **Travel router** — connects to hotel/venue WiFi upstream, shares a secured local network
2. **Tailscale integration** — joins the tailnet so all devices stay connected regardless of location
3. **Secure file storage** — files stored on the NVMe drives, not in the cloud
4. **Team remote access** — team members can access shared files remotely via Tailscale

## Stack

- **OS**: Raspberry Pi OS (or Ubuntu Server for Pi — TBD)
- **Networking**: hostapd (WiFi AP), iptables (routing/NAT)
- **DNS/DHCP**: Technitium DNS Server (Docker) — web UI on port 5380
- **VPN/mesh**: Tailscale
- **File sharing (team)**: Samba — technical team mounts as network drive, uploads to `/mnt/data/files/`
- **Public portal**: Nginx serving static HTML from a GitHub repo, auto-synced via cron `git pull`
- **File presentation**: HTML in the portal repo controls all download links — no directory listing exposed
- **Container runtime**: Docker + Docker Compose (for services)
- **Secrets**: 1Password CLI on the dev machine; secrets baked into Pi via secure setup script

## Project Structure

```
travel.router/
├── CLAUDE.md               # This file
├── .gitignore
├── docker/                 # Docker Compose services
├── config/                 # Service config files (hostapd, dnsmasq, tailscale, etc.)
├── scripts/                # Setup and maintenance scripts
│   ├── setup.sh            # Initial Pi provisioning
│   └── ...
└── docs/                   # Architecture decisions, network diagrams, notes
```

## Claude Code Setup

This project uses **OpenRouter free tier** to save Claude Pro credits during development.
- Config: `.claude/settings.local.json` (git-ignored)
- Credential resolved at startup via `.claude/get-token.sh` (calls 1Password)
- If the model feels slow/limited, switch to `cs` or `cr` alias from `~/` to use Claude Pro

## Key Decisions & Working Notes

> Add architectural decisions, constraints, and notes here as the project evolves.

- [x] DNS/DHCP: Technitium DNS Server in Docker
- [x] OS: Debian 13 (Trixie) — already installed on pinas01
- [x] DNS/DHCP: Technitium DNS Server in Docker
- [x] OS: Debian 13 (Trixie) — already installed on pinas01
- [x] Team file uploads: Samba (Docker, host networking)
- [x] Public portal: Nginx (Docker) + GitHub repo + cron git pull every 5 min
- [ ] Create portal GitHub repo and run setup-portal-sync.sh
- [ ] Add SAMBA_PASSWORD to 1Password at op://Private/travel-router/samba-password
- [ ] Decide on WiFi adapter strategy for travel AP mode (USB adapter recommended)
