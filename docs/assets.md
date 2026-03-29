# Hardware & Infrastructure Assets

## Raspberry Pi 5 — pinas01

| Property | Value |
|----------|-------|
| Model | Raspberry Pi 5 Model B Rev 1.0 |
| OS | Debian GNU/Linux 13 (Trixie) — 64-bit |
| Kernel | 6.12.62+rpt-rpi-2712 |
| RAM | 8GB |
| Swap | 2GB (zram) |
| Tailscale IP | 100.92.121.12 |
| LAN IP (wired) | 10.0.0.140 (eth0) |
| LAN IP (wireless) | 10.0.0.141 (wlan0) |
| SSH | `ssh pinas01` (via ~/.ssh/config + todd-ssh-key) |

## Storage

| Device | Size | Mount | Purpose |
|--------|------|-------|---------|
| nvme0n1 | 1.8TB | `/` | OS boot drive |
| nvme1n1 | 3.6TB | `/mnt/data` | Data / shared file storage |
| mmcblk0 | 58GB | unmounted | SD card (unused) |

**Total usable storage:** ~5.4TB (1.7TB OS drive free + 3.4TB data drive free)

All shared files and Docker volumes should live under `/mnt/data`.

## Installed Software

| Software | Version | Status |
|----------|---------|--------|
| Docker | 29.3.0 | Running |
| Tailscale | 1.94.2 | Running |
| SSH server | OpenSSH | Running |
| NetworkManager | — | Running |
| WPA supplicant | — | Running |

## Network Interfaces

| Interface | Address | Notes |
|-----------|---------|-------|
| eth0 | 10.0.0.140/24 | Wired LAN |
| wlan0 | 10.0.0.141/24 | Onboard WiFi (currently client mode) |
| tailscale0 | 100.92.121.12/32 | Tailnet — always-on remote access |

## Pending Hardware

- [ ] USB WiFi adapter — needed for dual-radio travel router mode (AP + upstream client simultaneously)

## Notes

- Pi boots from NVMe (nvme0n1), not the SD card — faster and more reliable
- Currently running a full desktop stack (lightdm, wayvnc, cups, bluetooth) — consider stripping to headless for production
- Both eth0 and wlan0 are on the LAN; for travel use, eth0 will connect to hotel/venue network and wlan0 (or USB adapter) will broadcast the local AP
