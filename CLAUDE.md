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
- **Networking**: hostapd (WiFi AP), dnsmasq (DHCP/DNS), iptables (routing/NAT)
- **VPN/mesh**: Tailscale
- **File sharing**: TBD (options: Samba, Nextcloud, Syncthing, or SFTP)
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

- [ ] Decide on file sharing service (Samba vs Nextcloud vs SFTP)
- [ ] Decide on Pi OS (Raspberry Pi OS Lite vs Ubuntu Server)
- [ ] Decide on WiFi adapter strategy for travel AP mode
