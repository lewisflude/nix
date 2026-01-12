#!/usr/bin/env bash
# Create all 10 semantic workspaces on startup for consistent ironbar display
# This ensures muscle memory for workspace navigation

sleep 2  # Wait for niri to fully start

# Create workspaces by briefly focusing them
for i in {1..10}; do
  niri msg action focus-workspace "$i" 2>/dev/null
  sleep 0.1
done

# Return to workspace 1
niri msg action focus-workspace 1 2>/dev/null
