#!/usr/bin/env bash

# filter_about_support.sh: extract key sections from a Firefox about:support log
# Usage: ./filter_about_support.sh about-support.txt

if [ -z "$1" ]; then
  echo "Usage: $0 <about-support.txt>"
  exit 1
fi

LOG="$1"

# Print application basics
rg -E '^(Build ID|Multiprocess Enabled|Version|User Agent|OS):' "$LOG"

echo
# Print graphics and WebRender info
rg -E '^(Compositor|WebRender|Adapter Description|Vendor ID|Device ID|Driver Version|Feature Status|GPU Accelerated Windows|Process Types|Layers):' "$LOG"

echo
# Print GPU process info
rg -E '^(GPU #|Active Process Type):' "$LOG"

echo
# Print about:support crash/reporting info
rg -E '^(Crash Reports Enabled|Minidump Path|Process Type):' "$LOG"

exit 0
