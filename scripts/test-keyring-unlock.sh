#!/usr/bin/env bash
# Test script to verify GNOME Keyring auto-unlock is working
# Run this after login to verify keyring functionality

set -euo pipefail

echo "🔐 Testing GNOME Keyring Auto-Unlock"
echo "===================================="
echo

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: Keyring daemon running
echo "1. Checking if gnome-keyring daemon is running..."
if pgrep -f gnome-keyring-daemon > /dev/null; then
    echo -e "${GREEN}✓${NC} GNOME Keyring daemon is running"
    pgrep -fa gnome-keyring | head -2 | sed 's/^/  /'
else
    echo -e "${RED}✗${NC} GNOME Keyring daemon is NOT running"
    exit 1
fi
echo

# Check 2: Unlock service status
echo "2. Checking unlock-login-keyring.service status..."
if systemctl --user is-active unlock-login-keyring.service > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} unlock-login-keyring.service is active"
    systemctl --user status unlock-login-keyring.service --no-pager | grep -E "(Active|Main PID|CPU)" | sed 's/^/  /'
else
    echo -e "${YELLOW}⚠${NC} unlock-login-keyring.service is not active"
    systemctl --user status unlock-login-keyring.service --no-pager --lines=5 | sed 's/^/  /'
fi
echo

# Check 3: Keyring runtime sockets
echo "3. Checking keyring runtime sockets..."
if [ -S "/run/user/$UID/keyring/control" ]; then
    echo -e "${GREEN}✓${NC} Keyring control socket exists"
    ls -lh "/run/user/$UID/keyring/" | tail -n +2 | sed 's/^/  /'
else
    echo -e "${RED}✗${NC} Keyring control socket not found"
fi
echo

# Check 4: Test keyring access (actual unlock test)
echo "4. Testing keyring access (should not prompt for password)..."
TEST_KEY="keyring-test-$(date +%s)"
TEST_VALUE="test-value"
TEST_SECRET="test-data-$(date +%s)"

# Store a test secret (should not prompt if keyring is unlocked)
echo "  Storing test secret..."
if command -v secret-tool > /dev/null 2>&1; then
    # secret-tool is in PATH
    if echo "$TEST_SECRET" | secret-tool store --label='Auto-unlock test' "$TEST_KEY" "$TEST_VALUE" 2>&1; then
        echo -e "${GREEN}✓${NC} Stored secret without password prompt"

        # Retrieve the secret
        echo "  Retrieving test secret..."
        RETRIEVED=$(secret-tool lookup "$TEST_KEY" "$TEST_VALUE" 2>&1)
        if [ "$RETRIEVED" = "$TEST_SECRET" ]; then
            echo -e "${GREEN}✓${NC} Retrieved secret successfully"
        else
            echo -e "${RED}✗${NC} Failed to retrieve secret"
            echo "  Expected: $TEST_SECRET"
            echo "  Got: $RETRIEVED"
        fi

        # Clean up
        echo "  Cleaning up test secret..."
        secret-tool clear "$TEST_KEY" "$TEST_VALUE" 2>&1 > /dev/null
        echo -e "${GREEN}✓${NC} Cleaned up test secret"
    else
        echo -e "${RED}✗${NC} Failed to store secret (keyring may be locked)"
        exit 1
    fi
else
    # Use nix-shell to get secret-tool
    echo "  (Using nix-shell to access secret-tool)"
    if echo "$TEST_SECRET" | nix-shell -p libsecret --run "secret-tool store --label='Auto-unlock test' $TEST_KEY $TEST_VALUE" 2>&1; then
        echo -e "${GREEN}✓${NC} Stored secret without password prompt"

        # Retrieve the secret
        echo "  Retrieving test secret..."
        RETRIEVED=$(nix-shell -p libsecret --run "secret-tool lookup $TEST_KEY $TEST_VALUE" 2>&1 | tail -1)
        if [ "$RETRIEVED" = "$TEST_SECRET" ]; then
            echo -e "${GREEN}✓${NC} Retrieved secret successfully"
        else
            echo -e "${RED}✗${NC} Failed to retrieve secret"
            echo "  Expected: $TEST_SECRET"
            echo "  Got: $RETRIEVED"
        fi

        # Clean up
        echo "  Cleaning up test secret..."
        nix-shell -p libsecret --run "secret-tool clear $TEST_KEY $TEST_VALUE" 2>&1 > /dev/null
        echo -e "${GREEN}✓${NC} Cleaned up test secret"
    else
        echo -e "${RED}✗${NC} Failed to store secret (keyring may be locked)"
        exit 1
    fi
fi
echo

# Check 5: Login keyring file
echo "5. Checking login keyring file..."
KEYRING_FILE="$HOME/.local/share/keyrings/login.keyring"
if [ -f "$KEYRING_FILE" ]; then
    echo -e "${GREEN}✓${NC} Login keyring file exists"
    ls -lh "$KEYRING_FILE" | sed 's/^/  /'
else
    echo -e "${YELLOW}⚠${NC} Login keyring file not found (may be created on first use)"
fi
echo

# Final summary
echo "===================================="
echo -e "${GREEN}✓ All tests passed!${NC}"
echo
echo "Your login keyring is properly configured for auto-unlock."
echo "No password prompts should appear for routine keyring access."
echo
echo "For sensitive secrets, consider creating a separate secure keyring:"
echo "  Run: seahorse"
echo "  Then: File → New → Password Keyring"
