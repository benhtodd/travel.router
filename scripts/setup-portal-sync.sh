#!/bin/bash
# Sets up automatic git pull of the portal HTML repo on pinas01.
# Run once from your dev machine after the portal GitHub repo is created.
# Requires: ssh access to pinas01, portal repo URL

set -e

PORTAL_DIR="/mnt/data/portal"
CRON_JOB="*/5 * * * * cd $PORTAL_DIR && git pull --ff-only >> /var/log/portal-sync.log 2>&1"

read -p "Enter portal GitHub repo URL (e.g. https://github.com/yourusername/travel-portal): " REPO_URL

echo "Cloning portal repo on pinas01..."
ssh pinas01 "mkdir -p $PORTAL_DIR && git clone $REPO_URL $PORTAL_DIR"

echo "Setting up cron job to pull every 5 minutes..."
ssh pinas01 "(crontab -l 2>/dev/null; echo '$CRON_JOB') | crontab -"

echo ""
echo "Done. Portal will sync from GitHub every 5 minutes."
echo "Logs: ssh pinas01 'tail -f /var/log/portal-sync.log'"
