#!/usr/bin/env bash
# Generate qBittorrent PBKDF2 password hash
# Usage: ./generate-qbittorrent-hash.sh <password>

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <password>"
  echo "Example: $0 'mySecurePassword123'"
  exit 1
fi

PASSWORD="$1"

# Generate PBKDF2 hash with random salt (qBittorrent format)
# qBittorrent uses SHA512 with 100000 iterations (version 4.6+)
# Older versions may use SHA256 with 32000 iterations
echo "$PASSWORD" | python3 << 'PYSCRIPT'
import hashlib, base64, sys, os
password = sys.stdin.read().strip().encode('utf-8')
# Generate random salt (qBittorrent uses 16 bytes)
salt = os.urandom(16)
# Use SHA512 with 100000 iterations (qBittorrent 4.6+)
hash_obj = hashlib.pbkdf2_hmac('sha512', password, salt, 100000)
salt_b64 = base64.b64encode(salt).decode('utf-8')
hash_b64 = base64.b64encode(hash_obj).decode('utf-8')
print(f"@ByteArray({salt_b64}:{hash_b64})")
PYSCRIPT
