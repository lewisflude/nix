#!/usr/bin/env bash
# Configure SABnzbd download directories
# Run this after SABnzbd has been started at least once to create its config file

set -euo pipefail

SABNZBD_CONFIG="${1:-/var/lib/sabnzbd/sabnzbd.ini}"
COMPLETE_DIR="${2:-/mnt/storage/usenet/complete}"
INCOMPLETE_DIR="${3:-/mnt/storage/usenet/incomplete}"

if [ ! -f "$SABNZBD_CONFIG" ]; then
    echo "Error: SABnzbd config file not found at $SABNZBD_CONFIG"
    echo "Please start SABnzbd at least once to create the config file."
    exit 1
fi

echo "Configuring SABnzbd directories..."
echo "  Config file: $SABNZBD_CONFIG"
echo "  Complete directory: $COMPLETE_DIR"
echo "  Incomplete directory: $INCOMPLETE_DIR"

# Backup config file
cp "$SABNZBD_CONFIG" "${SABNZBD_CONFIG}.bak.$(date +%Y%m%d_%H%M%S)"

# Use python to modify the config file (SABnzbd uses ConfigParser format)
python3 <<EOF
import configparser
import sys

config = configparser.ConfigParser()
config.read("$SABNZBD_CONFIG")

# Set directories in [misc] section
if 'misc' not in config:
    config.add_section('misc')

config['misc']['complete_dir'] = '$COMPLETE_DIR'
config['misc']['download_dir'] = '$INCOMPLETE_DIR'

# Also set in [folders] section if it exists
if 'folders' in config:
    config['folders']['complete_dir'] = '$COMPLETE_DIR'
    config['folders']['download_dir'] = '$INCOMPLETE_DIR'

with open("$SABNZBD_CONFIG", 'w') as f:
    config.write(f)

print("Configuration updated successfully!")
print("Restart SABnzbd service for changes to take effect:")
print("  sudo systemctl restart sabnzbd")
EOF
