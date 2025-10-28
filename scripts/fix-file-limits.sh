#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Fixing macOS file limits for Nix..."

# Step 1: Create system-level LaunchDaemon
echo "📝 Creating system LaunchDaemon..."
sudo tee /Library/LaunchDaemons/limit.maxfiles.plist > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>limit.maxfiles</string>
    <key>ProgramArguments</key>
    <array>
        <string>launchctl</string>
        <string>limit</string>
        <string>maxfiles</string>
        <string>65536</string>
        <string>524288</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ServiceIPC</key>
    <false/>
</dict>
</plist>
EOF

# Step 2: Set permissions and load daemon
echo "🔒 Setting permissions..."
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
sudo chmod 644 /Library/LaunchDaemons/limit.maxfiles.plist

echo "🚀 Loading system daemon..."
sudo launchctl unload -w /Library/LaunchDaemons/limit.maxfiles.plist 2>/dev/null || true
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist

# Step 3: Create user-level LaunchAgent
echo "👤 Creating user LaunchAgent..."
mkdir -p ~/Library/LaunchAgents
tee ~/Library/LaunchAgents/limit.maxfiles.plist > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>limit.maxfiles</string>
    <key>ProgramArguments</key>
    <array>
        <string>launchctl</string>
        <string>limit</string>
        <string>maxfiles</string>
        <string>65536</string>
        <string>524288</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

echo "🚀 Loading user agent..."
launchctl unload -w ~/Library/LaunchAgents/limit.maxfiles.plist 2>/dev/null || true
launchctl load -w ~/Library/LaunchAgents/limit.maxfiles.plist

# Step 4: Apply immediately for current session
echo "⚡ Applying limits to current session..."
sudo launchctl limit maxfiles 65536 524288

# Step 5: Add to shell configuration if not already present
if ! grep -q "ulimit -n 65536" ~/.zshrc 2>/dev/null; then
    echo "📄 Adding ulimit to .zshrc..."
    echo "" >> ~/.zshrc
    echo "# Increase file limit for Nix" >> ~/.zshrc
    echo "ulimit -n 65536" >> ~/.zshrc
fi

# Step 6: Set ulimit for current shell
ulimit -n 65536

# Step 7: Clear Nix cache
echo "🧹 Clearing Nix cache..."
rm -rf ~/.cache/nix/tarball-cache
nix-collect-garbage -d

# Step 8: Verify the changes
echo ""
echo "✅ File limits have been updated!"
echo ""
echo "📊 Current limits:"
echo -n "System maxfiles: "
launchctl limit maxfiles | awk '{print $2 " (soft) / " $3 " (hard)"}'
echo -n "Shell ulimit: "
ulimit -n
echo ""
echo "🎉 You can now retry your Nix operation!"
echo ""
echo "💡 Note: If you still experience issues, a system restart may be required."
