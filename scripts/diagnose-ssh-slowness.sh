#!/usr/bin/env bash
# Diagnose SSH connection slowness
# Usage: ./diagnose-ssh-slowness.sh [user@]hostname [port]

set -euo pipefail

HOST="${1:-}"
PORT="${2:-22}"

if [ -z "$HOST" ]; then
  echo "Usage: $0 [user@]hostname [port]"
  echo "Example: $0 root@192.168.1.1"
  exit 1
fi

HOSTNAME=$(echo "$HOST" | cut -d'@' -f2 | cut -d':' -f1)

echo "???????????????????????????????????????????????????????????"
echo "SSH Slowness Diagnostic for: $HOST"
echo "???????????????????????????????????????????????????????????"
echo ""

echo "1. Testing with verbose output to see where it hangs..."
echo "   (This will show each step of the connection process)"
echo ""
time ssh -v -o ConnectTimeout=10 -p "$PORT" "$HOST" exit 2>&1 | tee /tmp/ssh-verbose.log | grep -E "(Connecting to|Authenticating|debug1|compression|GSSAPI|DNS|delay|timeout)" || true
echo ""

echo "2. Checking for common slowness causes..."
echo ""

# Check DNS lookups
echo "   Testing DNS resolution time..."
DNS_START=$(date +%s.%N)
if host "$HOSTNAME" >/dev/null 2>&1; then
  DNS_END=$(date +%s.%N)
  DNS_TIME=$(echo "$DNS_END - $DNS_START" | bc)
  echo "   ? DNS lookup took ${DNS_TIME}s (this can cause SSH delays)"
else
  echo "   ? DNS lookup failed quickly (good - won't cause delays)"
fi
echo ""

# Test with optimizations
echo "3. Testing with performance optimizations applied..."
echo ""

OPTIMIZED_OPTS="-o ConnectTimeout=5 -o AddressFamily=inet -o Compression=no -o CheckHostIP=no -o PreferredAuthentications=keyboard-interactive,password"

echo "   Testing optimized connection..."
OPT_START=$(date +%s.%N)
if timeout 15 ssh $OPTIMIZED_OPTS -p "$PORT" "$HOST" exit 2>/dev/null; then
  OPT_END=$(date +%s.%N)
  OPT_TIME=$(echo "$OPT_END - $OPT_START" | bc)
  echo "   ? Optimized connection: ${OPT_TIME}s"
else
  echo "   ? Optimized connection failed or timed out"
fi
echo ""

# Compare with default
echo "4. Comparing default vs optimized..."
echo ""

echo "   Default SSH (may be slow):"
DEFAULT_START=$(date +%s.%N)
timeout 15 ssh -o ConnectTimeout=10 -p "$PORT" "$HOST" exit >/dev/null 2>&1 || true
DEFAULT_END=$(date +%s.%N)
DEFAULT_TIME=$(echo "$DEFAULT_END - $DEFAULT_START" | bc)
echo "   Time: ${DEFAULT_TIME}s"
echo ""

echo "   Optimized SSH (should be faster):"
OPT2_START=$(date +%s.%N)
timeout 15 ssh $OPTIMIZED_OPTS -p "$PORT" "$HOST" exit >/dev/null 2>&1 || true
OPT2_END=$(date +%s.%N)
OPT2_TIME=$(echo "$OPT2_END - $OPT2_START" | bc)
echo "   Time: ${OPT2_TIME}s"
echo ""

if (( $(echo "$OPT2_TIME < $DEFAULT_TIME" | bc -l) )); then
  IMPROVEMENT=$(echo "scale=1; (($DEFAULT_TIME - $OPT2_TIME) / $DEFAULT_TIME) * 100" | bc)
  echo "   ? Optimization improved speed by ${IMPROVEMENT}%"
else
  echo "   ? No significant improvement (may be network-related)"
fi
echo ""

echo "5. Recommendations:"
echo ""
echo "   Add these to your ~/.ssh/config for $HOSTNAME:"
echo ""
echo "   Host $HOSTNAME"
echo "     Hostname $HOSTNAME"
echo "     Port $PORT"
echo "     ConnectTimeout 5"
echo "     AddressFamily inet"
echo "     Compression no"
echo "     CheckHostIP no"
echo "     PreferredAuthentications keyboard-interactive,password"
echo "     # Disable GSSAPI (if causing issues)"
echo "     GSSAPIAuthentication no"
echo "     GSSAPIDelegateCredentials no"
echo ""
