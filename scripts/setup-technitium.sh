#!/bin/bash
# Sets up Technitium DNS/DHCP on pinas01.
# Run this once from your dev machine before first launch.
# Requires: ssh access to pinas01

set -e

echo "Creating data directories on pinas01..."
ssh pinas01 "sudo mkdir -p /mnt/data/technitium/config && sudo chown -R \$(whoami):\$(whoami) /mnt/data/technitium"

echo ""
echo "Setting admin password..."
read -s -p "Enter Technitium admin password: " PASS
echo ""
ssh pinas01 "echo '$PASS' > /mnt/data/technitium/config/admin-password && chmod 600 /mnt/data/technitium/config/admin-password"
unset PASS

echo ""
echo "Copying docker-compose.yml to pinas01..."
scp "$(dirname "$0")/../docker/technitium/docker-compose.yml" pinas01:/home/todd/docker/technitium/docker-compose.yml

echo ""
echo "Starting Technitium..."
ssh pinas01 "cd /home/todd/docker/technitium && docker compose up -d"

echo ""
echo "Done. Technitium web UI available at:"
echo "  Local:     http://10.0.0.140:5380"
echo "  Tailscale: http://100.92.121.12:5380"
