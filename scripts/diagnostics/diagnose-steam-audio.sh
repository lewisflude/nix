#!/usr/bin/env bash
# Diagnose Steam/Proton audio issues with PipeWire
# Usage: ./diagnose-steam-audio.sh

set -euo pipefail

echo "=== Steam/Proton Audio Diagnostics ==="
echo ""

echo "1. Checking PipeWire status..."
systemctl --user status pipewire pipewire-pulse wireplumber | grep -E "(Active:|Loaded:)" || true
echo ""

echo "2. Checking PulseAudio socket..."
if [ -e "/run/user/$(id -u)/pulse/native" ]; then
    echo "✓ PulseAudio socket exists at /run/user/$(id -u)/pulse/native"
    ls -la "/run/user/$(id -u)/pulse/native"
else
    echo "✗ PulseAudio socket NOT found at /run/user/$(id -u)/pulse/native"
fi
echo ""

echo "3. Checking available sinks..."
pactl list short sinks
echo ""

echo "4. Checking default sink..."
pactl info | grep "Default Sink"
echo ""

echo "5. Checking WirePlumber status..."
wpctl status | head -n 30
echo ""

echo "6. Checking Steam environment variables..."
if pgrep -x steam > /dev/null; then
    echo "✓ Steam is running"
    steam_pid=$(pgrep -x steam | head -n1)
    echo "Steam PID: $steam_pid"
    echo "Environment variables:"
    cat /proc/$steam_pid/environ | tr '\0' '\n' | grep -E "(SDL_AUDIO|PULSE|PIPEWIRE)" || echo "No audio env vars found"
else
    echo "✗ Steam is not running - launch Steam first"
fi
echo ""

echo "7. Current session environment variables..."
env | grep -E "(SDL_AUDIO|PULSE|PIPEWIRE|XDG_RUNTIME_DIR)" || echo "No audio env vars in current session"
echo ""

echo "8. Testing audio with paplay..."
if command -v paplay &> /dev/null; then
    echo "Playing test sound (you should hear a beep)..."
    paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>&1 || echo "Test sound failed"
else
    echo "paplay not found, skipping audio test"
fi
echo ""

echo "=== Diagnostic complete ==="
echo ""
echo "If games still don't show audio:"
echo "1. Restart Steam completely: steam -shutdown && steam"
echo "2. In Steam, right-click a game → Properties → Launch Options, add:"
echo "   SDL_AUDIODRIVER=pulseaudio %command%"
echo "3. Check game logs at: ~/.local/share/Steam/logs/"
echo "4. Run: PULSE_LOG=99 <game> to see PulseAudio debug output"
