#!/usr/bin/env bash
# Test internet download and upload speed through VLAN 2 (192.168.2.0/24)
# Usage: ./test-vlan2-speed.sh

set -euo pipefail

VLAN_INTERFACE="vlan2"
VLAN_IP="192.168.2.249"
GATEWAY="192.168.2.1"

echo "???????????????????????????????????????????????????????????????"
echo "VLAN 2 Internet Speed Test"
echo "???????????????????????????????????????????????????????????????"
echo ""

# Check if VLAN interface exists
echo "1. Checking VLAN 2 interface..."
if ! ip link show "$VLAN_INTERFACE" >/dev/null 2>&1; then
  echo "   ? Interface $VLAN_INTERFACE not found"
  echo "   Please ensure VLAN 2 is configured and active"
  exit 1
fi

# Check if interface is up
if ! ip link show "$VLAN_INTERFACE" | grep -q "state UP"; then
  echo "   ??  Interface $VLAN_INTERFACE exists but is not UP"
  echo "   Attempting to bring interface up..."
  sudo ip link set "$VLAN_INTERFACE" up || {
    echo "   ? Failed to bring interface up"
    exit 1
  }
fi

# Get interface IP
INTERFACE_IP=$(ip addr show "$VLAN_INTERFACE" | grep -oP 'inet \K[\d.]+' | head -1)
if [ -z "$INTERFACE_IP" ]; then
  echo "   ? No IP address assigned to $VLAN_INTERFACE"
  exit 1
fi

echo "   ? Interface: $VLAN_INTERFACE"
echo "   ? IP Address: $INTERFACE_IP"
echo "   ? Gateway: $GATEWAY"
echo ""

# Test gateway connectivity
echo "2. Testing gateway connectivity..."
if ping -c 2 -W 2 -I "$VLAN_INTERFACE" "$GATEWAY" >/dev/null 2>&1; then
  GATEWAY_RTT=$(ping -c 3 -W 2 -I "$VLAN_INTERFACE" "$GATEWAY" 2>/dev/null | tail -1 | awk -F '/' '{print $5}')
  echo "   ? Gateway reachable (RTT: ${GATEWAY_RTT}ms)"
else
  echo "   ? Gateway not reachable"
  exit 1
fi
echo ""

# Test DNS resolution through VLAN 2
echo "3. Testing DNS resolution..."
if dig @192.168.2.1 google.com +short +timeout=3 >/dev/null 2>&1; then
  echo "   ? DNS resolution working"
else
  echo "   ??  DNS resolution test failed (may still work)"
fi
echo ""

# Test internet connectivity
echo "4. Testing internet connectivity..."
if curl -s --max-time 5 --interface "$VLAN_INTERFACE" http://www.google.com >/dev/null 2>&1; then
  echo "   ? Internet connectivity confirmed"
else
  echo "   ? No internet connectivity through VLAN 2"
  exit 1
fi
echo ""

# Download speed test
echo "5. Testing download speed..."
echo "   Downloading test file (this may take a moment)..."
echo ""

# Use multiple test files for better accuracy
DOWNLOAD_URLS=(
  "http://ipv4.download.thinkbroadband.com/10MB.zip"
  "http://ipv4.download.thinkbroadband.com/20MB.zip"
  "http://speedtest.tele2.net/10MB.zip"
)

DOWNLOAD_RESULTS=()
for url in "${DOWNLOAD_URLS[@]}"; do
  echo "   Testing: $(basename "$url")"
  START_TIME=$(date +%s.%N)

  # Download with progress hidden, measure time
  if DOWNLOADED=$(curl -s --max-time 30 --interface "$VLAN_INTERFACE" -o /tmp/vlan2_speedtest_download.tmp "$url" 2>&1); then
    END_TIME=$(date +%s.%N)
    FILE_SIZE=$(stat -f%z /tmp/vlan2_speedtest_download.tmp 2>/dev/null || stat -c%s /tmp/vlan2_speedtest_download.tmp 2>/dev/null)
    DURATION=$(awk "BEGIN {printf \"%.3f\", $END_TIME - $START_TIME}")

    if [ -n "$FILE_SIZE" ] && [ "$FILE_SIZE" -gt 0 ]; then
      # Convert bytes to bits, then to Mbps
      SPEED_MBPS=$(awk "BEGIN {printf \"%.2f\", ($FILE_SIZE * 8) / ($DURATION * 1000000)}")
      DOWNLOAD_RESULTS+=("$SPEED_MBPS")
      echo "   ? Speed: ${SPEED_MBPS} Mbps (${FILE_SIZE} bytes in ${DURATION}s)"
    else
      echo "   ??  Could not determine file size"
    fi
    rm -f /tmp/vlan2_speedtest_download.tmp
  else
    echo "   ??  Download failed or timed out"
  fi
  echo ""
done

# Calculate average download speed
if [ ${#DOWNLOAD_RESULTS[@]} -gt 0 ]; then
  TOTAL=0
  for speed in "${DOWNLOAD_RESULTS[@]}"; do
    TOTAL=$(awk "BEGIN {printf \"%.2f\", $TOTAL + $speed}")
  done
  COUNT=${#DOWNLOAD_RESULTS[@]}
  AVG_DOWNLOAD=$(awk "BEGIN {printf \"%.2f\", $TOTAL / $COUNT}")
  echo "   Average download speed: ${AVG_DOWNLOAD} Mbps"
else
  AVG_DOWNLOAD=0
  echo "   ??  Could not calculate download speed"
fi
echo ""

# Upload speed test
echo "6. Testing upload speed..."
echo "   Uploading test data (this may take a moment)..."
echo ""

# Create a test file for upload (10MB)
TEST_FILE_SIZE=10485760  # 10MB
dd if=/dev/zero of=/tmp/vlan2_speedtest_upload.tmp bs=1024 count=10240 >/dev/null 2>&1

# Use httpbin.org for upload testing (accepts POST requests)
UPLOAD_URL="https://httpbin.org/post"

echo "   Uploading 10MB test file..."
START_TIME=$(date +%s.%N)

if curl -s --max-time 60 --interface "$VLAN_INTERFACE" \
  -X POST \
  -H "Content-Type: application/octet-stream" \
  --data-binary @/tmp/vlan2_speedtest_upload.tmp \
  "$UPLOAD_URL" >/dev/null 2>&1; then
  END_TIME=$(date +%s.%N)
  DURATION=$(awk "BEGIN {printf \"%.3f\", $END_TIME - $START_TIME}")

  # Convert bytes to bits, then to Mbps
  AVG_UPLOAD=$(awk "BEGIN {printf \"%.2f\", ($TEST_FILE_SIZE * 8) / ($DURATION * 1000000)}")
  echo "   ? Upload speed: ${AVG_UPLOAD} Mbps (${TEST_FILE_SIZE} bytes in ${DURATION}s)"
else
  AVG_UPLOAD=0
  echo "   ??  Upload test failed or timed out"
fi

rm -f /tmp/vlan2_speedtest_upload.tmp
echo ""

# Latency test
echo "7. Testing latency to external servers..."
LATENCY_TARGETS=(
  "8.8.8.8"
  "1.1.1.1"
  "www.google.com"
)

LATENCY_RESULTS=()
for target in "${LATENCY_TARGETS[@]}"; do
  if PING_RTT=$(ping -c 3 -W 2 -I "$VLAN_INTERFACE" "$target" 2>/dev/null | tail -1 | awk -F '/' '{print $5}'); then
    if [ -n "$PING_RTT" ]; then
      LATENCY_RESULTS+=("$PING_RTT")
      echo "   $target: ${PING_RTT}ms"
    fi
  fi
done

if [ ${#LATENCY_RESULTS[@]} -gt 0 ]; then
  TOTAL=0
  for lat in "${LATENCY_RESULTS[@]}"; do
    TOTAL=$(awk "BEGIN {printf \"%.2f\", $TOTAL + $lat}")
  done
  COUNT=${#LATENCY_RESULTS[@]}
  AVG_LATENCY=$(awk "BEGIN {printf \"%.2f\", $TOTAL / $COUNT}")
  echo "   Average latency: ${AVG_LATENCY}ms"
else
  AVG_LATENCY=0
  echo "   ??  Could not measure latency"
fi
echo ""

# Summary
echo "???????????????????????????????????????????????????????????????"
echo "Speed Test Summary"
echo "???????????????????????????????????????????????????????????????"
echo "Interface:     $VLAN_INTERFACE ($INTERFACE_IP)"
echo "Gateway:       $GATEWAY"
echo "Download:      ${AVG_DOWNLOAD} Mbps"
echo "Upload:        ${AVG_UPLOAD} Mbps"
echo "Latency:       ${AVG_LATENCY}ms"
echo ""

# Performance assessment
if [ -n "$AVG_DOWNLOAD" ] && [ "$AVG_DOWNLOAD" != "0" ]; then
  if awk "BEGIN {exit !($AVG_DOWNLOAD >= 100)}"; then
    echo "? Excellent download speed (>= 100 Mbps)"
  elif awk "BEGIN {exit !($AVG_DOWNLOAD >= 50)}"; then
    echo "? Good download speed (>= 50 Mbps)"
  elif awk "BEGIN {exit !($AVG_DOWNLOAD >= 10)}"; then
    echo "? Acceptable download speed (>= 10 Mbps)"
  else
    echo "? Slow download speed (< 10 Mbps)"
  fi
fi

if [ -n "$AVG_UPLOAD" ] && [ "$AVG_UPLOAD" != "0" ]; then
  if awk "BEGIN {exit !($AVG_UPLOAD >= 50)}"; then
    echo "? Excellent upload speed (>= 50 Mbps)"
  elif awk "BEGIN {exit !($AVG_UPLOAD >= 20)}"; then
    echo "? Good upload speed (>= 20 Mbps)"
  elif awk "BEGIN {exit !($AVG_UPLOAD >= 5)}"; then
    echo "? Acceptable upload speed (>= 5 Mbps)"
  else
    echo "? Slow upload speed (< 5 Mbps)"
  fi
fi

if [ -n "$AVG_LATENCY" ] && [ "$AVG_LATENCY" != "0" ]; then
  if awk "BEGIN {exit !($AVG_LATENCY < 20)}"; then
    echo "? Excellent latency (< 20ms)"
  elif awk "BEGIN {exit !($AVG_LATENCY < 50)}"; then
    echo "? Good latency (< 50ms)"
  elif awk "BEGIN {exit !($AVG_LATENCY < 100)}"; then
    echo "? Acceptable latency (< 100ms)"
  else
    echo "? High latency (>= 100ms)"
  fi
fi

echo ""
