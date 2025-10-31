#!/usr/bin/env python3
import yaml
import sys
import subprocess

# Decrypt the secrets file
decrypted = subprocess.run(['sops', '-d', 'secrets/secrets.yaml'],
                          capture_output=True, text=True, check=True)
data = yaml.safe_load(decrypted.stdout)

# Update the structure
if 'qbittorrent' not in data:
    data['qbittorrent'] = {}

if 'webui' not in data['qbittorrent'] or not isinstance(data['qbittorrent']['webui'], dict):
    data['qbittorrent']['webui'] = {}

data['qbittorrent']['webui']['username'] = 'lewis'
data['qbittorrent']['webui']['password_hash'] = '@ByteArray(BG5UeWmPhwkjAc6oI3jweA==:V+qMWWaiBTzyIUtk9/vhxMUEkGGPi8/ALIESmIHVxb4=)'

# Write to temp file
import tempfile
with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.yaml') as f:
    yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)
    temp_file = f.name

# Re-encrypt
subprocess.run(['sops', '-e', temp_file], stdout=open('secrets/secrets.yaml', 'w'), check=True)

# Clean up
import os
os.unlink(temp_file)

print("✓ Secrets file updated successfully")
