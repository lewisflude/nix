#!/usr/bin/env bash
# Keyboard Configuration Test Script
# Tests v2.0 Ergonomic Hybrid layout on NixOS

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  Keyboard Configuration Test - v2.0 Ergonomic Hybrid"
echo "═══════════════════════════════════════════════════════════════"
echo

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test 1: Check keyd service
echo -e "${BLUE}[1/6] Checking keyd service status...${NC}"
if systemctl is-active --quiet keyd; then
  echo -e "${GREEN}✓ keyd is running${NC}"
else
  echo -e "${RED}✗ keyd is NOT running${NC}"
  echo "  Fix: sudo systemctl start keyd"
  exit 1
fi
echo

# Test 2: Check configuration file
echo -e "${BLUE}[2/6] Checking keyd configuration...${NC}"
if [ -f /etc/keyd/default.conf ]; then
  echo -e "${GREEN}✓ Configuration file exists${NC}"
  echo "  Location: /etc/keyd/default.conf"

  # Check for key remappings
  if grep -q "overload(super, esc)" /etc/keyd/default.conf 2>/dev/null; then
    echo -e "${GREEN}✓ Caps Lock remapping configured${NC}"
  else
    echo -e "${YELLOW}⚠ Caps Lock remapping not found${NC}"
  fi

  if grep -q "layer(nav)" /etc/keyd/default.conf 2>/dev/null; then
    echo -e "${GREEN}✓ Navigation layer configured${NC}"
  else
    echo -e "${YELLOW}⚠ Navigation layer not found${NC}"
  fi
else
  echo -e "${RED}✗ Configuration file not found${NC}"
  echo "  Expected: /etc/keyd/default.conf"
fi
echo

# Test 3: Check keyd logs for errors
echo -e "${BLUE}[3/6] Checking recent keyd logs...${NC}"
if journalctl -u keyd -n 10 --no-pager | grep -i error > /dev/null; then
  echo -e "${YELLOW}⚠ Errors found in logs:${NC}"
  journalctl -u keyd -n 5 --no-pager | grep -i error
else
  echo -e "${GREEN}✓ No recent errors${NC}"
fi
echo

# Test 4: List matched devices
echo -e "${BLUE}[4/6] Keyboards detected by keyd:${NC}"
journalctl -u keyd --since "1 hour ago" --no-pager | grep "DEVICE: match" | tail -5 || echo "No devices found in recent logs"
echo

# Test 5: Check if wev is available
echo -e "${BLUE}[5/6] Checking for testing tools...${NC}"
if command -v wev &> /dev/null; then
  echo -e "${GREEN}✓ wev is installed (recommended for visual testing)${NC}"
  echo "  Run: wev"
else
  echo -e "${YELLOW}⚠ wev is not installed${NC}"
  echo "  Install: Add 'wev' to your packages list"
fi

if command -v evtest &> /dev/null; then
  echo -e "${GREEN}✓ evtest is installed${NC}"
else
  echo -e "${YELLOW}⚠ evtest is not installed${NC}"
fi
echo

# Test 6: Interactive test guidance
echo -e "${BLUE}[6/6] Manual Testing Guide${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo
echo -e "${GREEN}Test these key combinations:${NC}"
echo
echo "  1. Caps Lock (Tap)  → Should produce Escape"
echo "     Test: Tap Caps Lock in a terminal (should NOT capitalize)"
echo
echo "  2. Caps Lock (Hold) → Should act as Super/Meta"
echo "     Test: Hold Caps + T (should open terminal)"
echo "     Test: Hold Caps + D (should open launcher)"
echo
echo "  3. F13 Key → Should act as Super/Meta"
echo "     Test: Press F13 + T (should open terminal)"
echo
echo "  4. Right Alt + H/J/K/L → Should produce arrow keys"
echo "     Test: Hold Right Alt, press H/J/K/L (cursor should move)"
echo
echo "  5. Right Alt + Y/O → Should produce Home/End"
echo "     Test: Hold Right Alt, press Y or O (jump to line start/end)"
echo
echo "  6. Right Alt + C/V → Should Copy/Paste"
echo "     Test: Select text, Right Alt + C, then Right Alt + V"
echo
echo "═══════════════════════════════════════════════════════════════"
echo
echo -e "${YELLOW}For detailed key event testing, run:${NC}"
echo "  wev                  # Visual key event viewer (install if needed)"
echo "  sudo evtest          # Low-level event testing"
echo
echo -e "${YELLOW}To restart keyd after config changes:${NC}"
echo "  sudo systemctl restart keyd"
echo
echo -e "${YELLOW}To view live keyd logs:${NC}"
echo "  journalctl -u keyd -f"
echo
echo "═══════════════════════════════════════════════════════════════"

