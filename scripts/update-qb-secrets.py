#!/usr/bin/env python3
"""
Update qBittorrent secrets in secrets.yaml
"""
import subprocess
import yaml
import tempfile
import os
import sys

# Configuration
SECRETS_FILE = 'secrets/secrets.yaml'
# Username can be set via QB_USERNAME env var, defaults to 'lewis'
USERNAME = os.environ.get('QB_USERNAME', 'lewis')

# Password hash - should be generated using qBittorrent's password hash format
# This is a placeholder - update with your actual password hash
PASSWORD_HASH = os.environ.get('QB_PASSWORD_HASH', '@ByteArray(BG5UeWmPhwkjAc6oI3jweA==:V+qMWWaiBTzyIUtk9/vhxMUEkGGPi8/ALIESmIHVxb4=)')

def main():
    temp_file = None
    try:
        # Check if secrets file exists
        if not os.path.exists(SECRETS_FILE):
            print(f"Error: Secrets file not found: {SECRETS_FILE}", file=sys.stderr)
            sys.exit(1)

        # Decrypt secrets
        try:
            result = subprocess.run(
                ['sops', '-d', SECRETS_FILE],
                capture_output=True,
                text=True,
                check=True
            )
        except subprocess.CalledProcessError as e:
            print(f"Error decrypting secrets file: {e.stderr}", file=sys.stderr)
            sys.exit(1)
        except FileNotFoundError:
            print("Error: sops command not found. Please install sops.", file=sys.stderr)
            sys.exit(1)

        # Parse YAML
        try:
            data = yaml.safe_load(result.stdout)
            if data is None:
                data = {}
        except yaml.YAMLError as e:
            print(f"Error parsing YAML: {e}", file=sys.stderr)
            sys.exit(1)

        # Update qbittorrent.webui structure
        if 'qbittorrent' not in data:
            data['qbittorrent'] = {}

        # Preserve existing username if present, otherwise use configured username
        existing_username = None
        if 'qbittorrent' in data and 'webui' in data['qbittorrent']:
            if isinstance(data['qbittorrent']['webui'], dict):
                existing_username = data['qbittorrent']['webui'].get('username')

        data['qbittorrent']['webui'] = {
            'username': existing_username or USERNAME,
            'password_hash': PASSWORD_HASH
        }

        # Write to temp file
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.yaml') as f:
            yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)
            temp_file = f.name

        # Encrypt with sops
        try:
            encrypt_result = subprocess.run(
                ['sops', '-e', temp_file],
                capture_output=True,
                text=True,
                check=True
            )
        except subprocess.CalledProcessError as e:
            print(f"Error encrypting: {e.stderr}", file=sys.stderr)
            print("\nPlease run manually:", file=sys.stderr)
            print(f"  sops -e {temp_file} > {SECRETS_FILE}", file=sys.stderr)
            sys.exit(1)

        # Write encrypted content to secrets file
        try:
            with open(SECRETS_FILE, 'w') as f:
                f.write(encrypt_result.stdout)
        except IOError as e:
            print(f"Error writing secrets file: {e}", file=sys.stderr)
            sys.exit(1)

        print("✓ Secrets file updated successfully")
        print(f"  Username: {data['qbittorrent']['webui']['username']}")

    except KeyboardInterrupt:
        print("\nInterrupted by user", file=sys.stderr)
        sys.exit(130)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        # Clean up temp file
        if temp_file and os.path.exists(temp_file):
            try:
                os.unlink(temp_file)
            except OSError:
                pass  # Ignore cleanup errors

if __name__ == '__main__':
    main()
