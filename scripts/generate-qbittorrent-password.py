#!/usr/bin/env nix-shell
#! nix-shell -i python3 -p python3
"""
Generate PBKDF2-SHA512 password hash for qBittorrent WebUI.
Compatible with qBittorrent's Password_PBKDF2 format.

Usage:
  ./scripts/generate-qbittorrent-password.py

The script will prompt for a password and output the hash in the format:
  @ByteArray(salt:hash)

This can be stored in SOPS as: qbittorrent/webui/password-pbkdf2
"""

import hashlib
import secrets
import base64
import getpass


def generate_qbittorrent_password(password: str) -> str:
    """
    Generate qBittorrent-compatible PBKDF2-SHA512 password hash.

    Args:
        password: Plain text password

    Returns:
        Formatted hash string: @ByteArray(salt:hash)
    """
    # Generate 16-byte random salt
    salt = secrets.token_bytes(16)

    # Generate PBKDF2-SHA512 hash with 100,000 iterations
    password_bytes = password.encode('utf-8')
    hash_bytes = hashlib.pbkdf2_hmac(
        'sha512',
        password_bytes,
        salt,
        100000
    )

    # Base64 encode salt and hash
    salt_b64 = base64.b64encode(salt).decode('ascii')
    hash_b64 = base64.b64encode(hash_bytes).decode('ascii')

    # Format as qBittorrent expects
    return f"@ByteArray({salt_b64}:{hash_b64})"


def main():
    print("qBittorrent Password Hash Generator")
    print("=" * 50)
    print()

    # Prompt for password (with confirmation)
    while True:
        password = getpass.getpass("Enter password: ")
        password_confirm = getpass.getpass("Confirm password: ")

        if password == password_confirm:
            break
        print("Passwords don't match. Try again.\n")

    # Generate hash
    password_hash = generate_qbittorrent_password(password)

    print()
    print("Generated PBKDF2 hash:")
    print("-" * 50)
    print(password_hash)
    print("-" * 50)
    print()
    print("To use this hash:")
    print("1. Add to secrets/secrets.yaml:")
    print("   qbittorrent:")
    print("     webui:")
    print("       username: your_username")
    print(f"       password-pbkdf2: {password_hash}")
    print()
    print("2. Uncomment the SOPS secrets in modules/services/qbittorrent.nix")
    print("3. Rebuild your system: nh os switch")


if __name__ == "__main__":
    main()
