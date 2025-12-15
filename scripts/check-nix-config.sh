#!/usr/bin/env bash
# Check current Nix configuration for substituters and trusted settings

echo "=================================================="
echo "Current Nix Configuration Check"
echo "=================================================="
echo ""

echo "1. System-level substituters:"
echo "------------------------------"
nix config show | grep "^substituters = " | sed 's/substituters = //' | tr ' ' '\n' | nl
echo ""

echo "2. Checking for Zed Cachix specifically:"
echo "----------------------------------------"
if nix config show | grep -q "zed.cachix.org"; then
    echo " zed.cachix.org is configured"
else
    echo "L zed.cachix.org is NOT configured"
fi
echo ""

echo "3. Trusted users:"
echo "-----------------"
nix config show | grep "^trusted-users = " || echo "Not set"
echo ""

echo "4. Current user trusted status:"
echo "-------------------------------"
CURRENT_USER=$(whoami)
if nix config show | grep "^trusted-users = " | grep -q "$CURRENT_USER"; then
    echo " You ($CURRENT_USER) are a trusted user"
else
    echo "   You ($CURRENT_USER) may not be in trusted-users"
    echo "   This is normal - system daemons will use the caches"
fi
echo ""

echo "5. Nix daemon status:"
echo "--------------------"
if pgrep -q nix-daemon; then
    echo " Nix daemon is running"
else
    echo "L Nix daemon is NOT running"
fi
echo ""

echo "6. Configuration file locations:"
echo "--------------------------------"
echo "System config: /etc/nix/nix.conf"
if [ -f /etc/nix/nix.conf ]; then
    echo "   Exists"
else
    echo "  L Does not exist"
fi

echo "User config: ~/.config/nix/nix.conf"
if [ -f ~/.config/nix/nix.conf ]; then
    echo "   Exists (but may be ignored for substituters)"
else
    echo "  L Does not exist"
fi
echo ""
