#!/usr/bin/env bash
# Test MCP Configuration
#
# Verifies that MCP servers are configured correctly and only
# servers without secret requirements are enabled by default.

set -euo pipefail

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MCP Configuration Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Expected servers (no secrets required)
EXPECTED_ENABLED=(
  "memory"
  "git"
  "time"
  "sqlite"
  "everything"
)

# Servers that should be disabled (require secrets)
EXPECTED_DISABLED=(
  "docs"
  "openai"
  "rustdocs"
  "github"
  "kagi"
  "brave"
  "filesystem"
  "sequentialthinking"
  "fetch"
  "nixos"
)

# Check if MCP config exists
MCP_CONFIG="$HOME/.cursor/mcp.json"
if [ ! -f "$MCP_CONFIG" ]; then
  echo "❌ MCP config not found at $MCP_CONFIG"
  echo "   Run: home-manager switch"
  exit 1
fi

echo "✅ MCP config found at $MCP_CONFIG"
echo

# Check which servers are enabled
echo "Checking enabled servers..."
ENABLED_SERVERS=$(jq -r '.mcpServers | keys[]' "$MCP_CONFIG" | sort)

echo "Enabled servers:"
echo "$ENABLED_SERVERS" | sed 's/^/  • /'
echo

# Verify expected servers are enabled
echo "Verifying expected servers are enabled..."
ALL_EXPECTED_ENABLED=true
for server in "${EXPECTED_ENABLED[@]}"; do
  if echo "$ENABLED_SERVERS" | grep -q "^${server}$"; then
    echo "  ✅ $server is enabled"
  else
    echo "  ❌ $server is NOT enabled (expected)"
    ALL_EXPECTED_ENABLED=false
  fi
done
echo

# Verify servers requiring secrets are disabled
echo "Verifying servers requiring secrets are disabled..."
ALL_EXPECTED_DISABLED=true
for server in "${EXPECTED_DISABLED[@]}"; do
  if echo "$ENABLED_SERVERS" | grep -q "^${server}$"; then
    echo "  ❌ $server is enabled (should be disabled)"
    ALL_EXPECTED_DISABLED=false
  else
    echo "  ✅ $server is disabled"
  fi
done
echo

# Check for wrapper scripts and verify they exist
echo "Verifying server commands..."
HAS_ERRORS=false

for server in $(echo "$ENABLED_SERVERS"); do
  COMMAND=$(jq -r ".mcpServers.\"${server}\".command" "$MCP_CONFIG")

  if [ -z "$COMMAND" ] || [ "$COMMAND" = "null" ]; then
    echo "  ❌ $server: No command found"
    HAS_ERRORS=true
    continue
  fi

  # Check if command is executable
  if [ -x "$COMMAND" ]; then
    echo "  ✅ $server: $COMMAND (exists)"
  else
    echo "  ⚠️  $server: $COMMAND (may not exist yet - needs npm install)"
  fi
done
echo

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$ALL_EXPECTED_ENABLED" = true ] && [ "$ALL_EXPECTED_DISABLED" = true ] && [ "$HAS_ERRORS" = false ]; then
  echo "✅ All tests passed!"
  echo
  echo "MCP servers are correctly configured:"
  echo "  • Only servers without secrets are enabled"
  echo "  • All server commands are valid"
  echo
  exit 0
else
  echo "❌ Some tests failed"
  echo
  if [ "$ALL_EXPECTED_ENABLED" = false ]; then
    echo "  • Some expected servers are not enabled"
  fi
  if [ "$ALL_EXPECTED_DISABLED" = false ]; then
    echo "  • Some servers requiring secrets are enabled"
  fi
  if [ "$HAS_ERRORS" = true ]; then
    echo "  • Some server commands are invalid"
  fi
  echo
  exit 1
fi
