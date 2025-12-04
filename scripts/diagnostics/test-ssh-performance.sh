#!/usr/bin/env bash
# Test SSH connection performance
# Usage: ./test-ssh-performance.sh [user@]hostname [port]

set -euo pipefail

HOST="${1:-}"
PORT="${2:-22}"

if [ -z "$HOST" ]; then
  echo "Usage: $0 [user@]hostname [port]"
  echo "Example: $0 root@192.168.10.1"
  echo "Example: $0 root@192.168.10.1 2222"
  exit 1
fi

# Extract hostname for display
HOSTNAME=$(echo "$HOST" | cut -d'@' -f2 | cut -d':' -f1)

echo "???????????????????????????????????????????????????????????"
echo "SSH Performance Test for: $HOST"
echo "???????????????????????????????????????????????????????????"
echo ""

# Check if we can connect at all
echo "1. Testing basic connectivity..."
echo "   Testing connection to $HOSTNAME:$PORT..."

# First, try to see what the actual error is
SSH_ERROR=$(timeout 5 ssh -o ConnectTimeout=3 -o BatchMode=yes -p "$PORT" "$HOST" exit 2>&1 || true)

if echo "$SSH_ERROR" | grep -q "Permission denied"; then
  echo "   ? Permission denied - public key not authorized"
  echo "   Trying with interactive authentication (you may be prompted)..."
  echo ""

  # Test with interactive auth
  CONNECT_START=$(date +%s.%N)
  if timeout 10 ssh -o ConnectTimeout=5 -p "$PORT" "$HOST" exit 2>/dev/null; then
    CONNECT_END=$(date +%s.%N)
    CONNECT_TIME=$(echo "$CONNECT_END - $CONNECT_START" | bc)
    echo "   ? Connection established in ${CONNECT_TIME}s (interactive auth)"
    USE_BATCHMODE=false
  else
    echo "   ? Failed to establish connection with interactive auth"
    echo ""
    echo "   Troubleshooting:"
    echo "   - Check if SSH is running on the remote host"
    echo "   - Verify the hostname/IP is correct: $HOSTNAME"
    echo "   - Check if port $PORT is correct"
    echo "   - Ensure your SSH key is authorized (or password auth is enabled)"
    echo ""
    echo "   To test connectivity manually:"
    echo "   ssh -v -p $PORT $HOST"
    exit 1
  fi
elif echo "$SSH_ERROR" | grep -q "Connection refused\|Connection timed out\|No route to host"; then
  echo "   ? Network connectivity issue"
  echo ""
  echo "   Error: $(echo "$SSH_ERROR" | head -1)"
  echo ""
  echo "   Troubleshooting:"
  echo "   - Check if SSH is running on the remote host: ssh -p $PORT $HOSTNAME"
  echo "   - Verify the hostname/IP is correct: $HOSTNAME"
  echo "   - Check if port $PORT is correct and firewall allows it"
  echo "   - Test network connectivity: ping $HOSTNAME"
  echo ""
  echo "   To test connectivity manually:"
  echo "   ssh -v -p $PORT $HOST"
  exit 1
elif timeout 5 ssh -o ConnectTimeout=3 -o BatchMode=yes -p "$PORT" "$HOST" exit >/dev/null 2>&1; then
  USE_BATCHMODE=true
  CONNECT_START=$(date +%s.%N)
  ssh -o ConnectTimeout=5 -o BatchMode=yes -p "$PORT" "$HOST" exit >/dev/null 2>&1
  CONNECT_END=$(date +%s.%N)
  CONNECT_TIME=$(echo "$CONNECT_END - $CONNECT_START" | bc)
  echo "   ? Connection established in ${CONNECT_TIME}s (public key auth)"
else
  echo "   ? Connection test failed"
  echo "   Trying with interactive authentication (you may be prompted)..."
  echo ""

  # Test with interactive auth
  CONNECT_START=$(date +%s.%N)
  if timeout 10 ssh -o ConnectTimeout=5 -p "$PORT" "$HOST" exit 2>/dev/null; then
    CONNECT_END=$(date +%s.%N)
    CONNECT_TIME=$(echo "$CONNECT_END - $CONNECT_START" | bc)
    echo "   ? Connection established in ${CONNECT_TIME}s (interactive auth)"
    USE_BATCHMODE=false
  else
    echo "   ? Failed to establish connection"
    echo ""
    echo "   Troubleshooting:"
    echo "   - Check if SSH is running on the remote host"
    echo "   - Verify the hostname/IP is correct: $HOSTNAME"
    echo "   - Check if port $PORT is correct"
    echo "   - Ensure your SSH key is authorized (or password auth is enabled)"
    echo ""
    echo "   To test connectivity manually:"
    echo "   ssh -v -p $PORT $HOST"
    exit 1
  fi
fi
echo ""

# Test 2: Authentication time
echo "2. Testing authentication time..."
AUTH_START=$(date +%s.%N)
if [ "$USE_BATCHMODE" = true ]; then
  ssh -o ConnectTimeout=5 -o BatchMode=yes -p "$PORT" "$HOST" exit >/dev/null 2>&1
else
  ssh -o ConnectTimeout=5 -p "$PORT" "$HOST" exit >/dev/null 2>&1
fi
AUTH_END=$(date +%s.%N)
AUTH_TIME=$(echo "$AUTH_END - $AUTH_START" | bc)
echo "   ? Authentication completed in ${AUTH_TIME}s"
echo ""

# Test 3: Multiple rapid connections (tests connection reuse)
echo "3. Testing connection multiplexing (5 rapid connections)..."
MULTIPLEX_START=$(date +%s.%N)
SSH_MULTIPLEX_OPTS="-o ConnectTimeout=5"
[ "$USE_BATCHMODE" = true ] && SSH_MULTIPLEX_OPTS="$SSH_MULTIPLEX_OPTS -o BatchMode=yes"

for i in {1..5}; do
  ssh $SSH_MULTIPLEX_OPTS -p "$PORT" "$HOST" exit >/dev/null 2>&1 &
done
wait
MULTIPLEX_END=$(date +%s.%N)
MULTIPLEX_TIME=$(echo "$MULTIPLEX_END - $MULTIPLEX_START" | bc)
echo "   ? 5 connections completed in ${MULTIPLEX_TIME}s (avg: $(echo "scale=3; $MULTIPLEX_TIME / 5" | bc)s per connection)"
echo ""

# Test 4: Command execution latency
echo "4. Testing command execution latency..."
LATENCY_RESULTS=()
SSH_OPTS="-o ConnectTimeout=5"
[ "$USE_BATCHMODE" = true ] && SSH_OPTS="$SSH_OPTS -o BatchMode=yes"

for i in {1..10}; do
  START=$(date +%s.%N)
  ssh $SSH_OPTS -p "$PORT" "$HOST" "echo test" >/dev/null 2>&1
  END=$(date +%s.%N)
  LATENCY=$(echo "$END - $START" | bc)
  LATENCY_RESULTS+=("$LATENCY")
done

# Calculate average
TOTAL=0
for lat in "${LATENCY_RESULTS[@]}"; do
  TOTAL=$(echo "$TOTAL + $lat" | bc)
done
AVG_LATENCY=$(echo "scale=3; $TOTAL / 10" | bc)

# Find min and max
MIN_LATENCY=$(printf '%s\n' "${LATENCY_RESULTS[@]}" | sort -n | head -1)
MAX_LATENCY=$(printf '%s\n' "${LATENCY_RESULTS[@]}" | sort -n | tail -1)

echo "   ? Average latency: ${AVG_LATENCY}s"
echo "   ? Min latency: ${MIN_LATENCY}s"
echo "   ? Max latency: ${MAX_LATENCY}s"
echo ""

# Test 5: Network connectivity (ping test)
echo "5. Testing network connectivity (ping)..."
if command -v ping >/dev/null 2>&1; then
  PING_RESULT=$(ping -c 3 -W 2 "$HOSTNAME" 2>/dev/null | tail -1 | awk -F '/' '{print $5}')
  if [ -n "$PING_RESULT" ]; then
    echo "   ? Average ping: ${PING_RESULT}ms"
  else
    echo "   ? Ping test failed or not available"
  fi
else
  echo "   ? ping command not available"
fi
echo ""

# Test 6: SSH verbose connection (shows what's happening)
echo "6. Verbose connection analysis (first connection)..."
echo "   Running: ssh -v -o ConnectTimeout=5 $HOST 'exit'"
echo "   (This shows the connection process)"
echo ""
SSH_VERBOSE_OPTS="-v -o ConnectTimeout=5"
[ "$USE_BATCHMODE" = true ] && SSH_VERBOSE_OPTS="$SSH_VERBOSE_OPTS -o BatchMode=yes"
ssh $SSH_VERBOSE_OPTS -p "$PORT" "$HOST" exit 2>&1 | grep -E "(Connecting to|Authenticating|Authenticated|debug1|compression)" | head -15
echo ""

# Test 7: Check if ControlMaster is working
echo "7. Testing connection multiplexing (ControlMaster)..."
CONTROL_PATH="$HOME/.ssh/master-*@${HOSTNAME}:${PORT}"
if ls $CONTROL_PATH >/dev/null 2>&1; then
  echo "   ? ControlMaster socket found - multiplexing is active"
  ls -lh $CONTROL_PATH 2>/dev/null | awk '{print "   Socket: " $9 " (" $5 ")"}'
else
  echo "   ? No ControlMaster socket found (may need to establish first connection)"
fi
echo ""

# Summary
echo "???????????????????????????????????????????????????????????"
echo "Performance Summary"
echo "???????????????????????????????????????????????????????????"
echo "Initial connection: ${CONNECT_TIME}s"
echo "Authentication:     ${AUTH_TIME}s"
echo "Average latency:    ${AVG_LATENCY}s"
echo ""

# Performance assessment
if (( $(echo "$AVG_LATENCY < 0.1" | bc -l) )); then
  echo "? Excellent performance (< 100ms)"
elif (( $(echo "$AVG_LATENCY < 0.3" | bc -l) )); then
  echo "? Good performance (< 300ms)"
elif (( $(echo "$AVG_LATENCY < 0.5" | bc -l) )); then
  echo "? Acceptable performance (< 500ms)"
else
  echo "? Slow performance (> 500ms) - consider optimization"
fi
