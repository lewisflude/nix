#!/usr/bin/env python3
"""
Update qBittorrent secrets in secrets.yaml
"""
import subprocess
import yaml
import tempfile
import os

# Decrypt secrets
result = subprocess.run(['sops', '-d', 'secrets/secrets.yaml'],
                       capture_output=True, text=True, check=True)
data = yaml.safe_load(result.stdout)

# Update qbittorrent.webui structure
if 'qbittorrent' not in data:
    data['qbittorrent'] = {}

# Set the new structure
data['qbittorrent']['webui'] = {
    'username': 'lewis',
    'password_hash': '@ByteArray(BG5UeWmPhwkjAc6oI3jweA==:V+qMWWaiBTzyIUtk9/vhxMUEkGGPi8/ALIESmIHVxb4=)'
}

# Write to temp file
with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.yaml') as f:
    yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)
    temp_file = f.name

try:
    # Encrypt with sops
    encrypt_result = subprocess.run(['sops', '-e', temp_file],
                                   capture_output=True, text=True, check=True)

    # Write encrypted content to secrets file
    with open('secrets/secrets.yaml', 'w') as f:
        f.write(encrypt_result.stdout)

    print("✓ Secrets file updated successfully")
except subprocess.CalledProcessError as e:
    print(f"Error encrypting: {e.stderr}")
    print("\nPlease run manually:")
    print(f"  sops -e {temp_file} > secrets/secrets.yaml")
finally:
    os.unlink(temp_file)
