# Diagnostic & Troubleshooting Scripts

Scripts for diagnosing system issues, particularly SSH performance and audio problems. These are interactive diagnostic tools designed to identify root causes of common problems.

**Integration**: Standalone diagnostic tools (manual execution)

## Available Scripts (3 scripts)

### SSH Diagnostics

#### `diagnose-ssh-slowness.sh`

**Integration**: standalone diagnostic tool
**Purpose**: Diagnose SSH connection slowness and identify bottlenecks

**Usage**:

```bash
./scripts/diagnostics/diagnose-ssh-slowness.sh [user@]hostname [port]
```

**Examples**:

```bash
# Basic usage
./scripts/diagnostics/diagnose-ssh-slowness.sh jupiter

# With username
./scripts/diagnostics/diagnose-ssh-slowness.sh lewis@jupiter

# Custom port
./scripts/diagnostics/diagnose-ssh-slowness.sh jupiter 2222
```

**Diagnoses**:

1. **DNS Resolution** - Slow DNS lookups delay connection
2. **Network Latency** - High ping times affect responsiveness
3. **SSH Handshake** - Key exchange and authentication speed
4. **Encryption Overhead** - Cipher performance impact
5. **Compression** - Whether compression helps or hurts
6. **SSH Config Issues** - Problematic settings

**Output Example**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 SSH Connection Diagnostics: jupiter
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. DNS Resolution
   jupiter → 192.168.1.50 (12ms)
   ⚠️ DNS lookup is slow (>10ms)
   Recommendation: Add to /etc/hosts

2. Network Latency
   Ping: 2.3ms (avg)
   ✓ Latency is good

3. SSH Handshake
   Connection time: 450ms
   ⚠️ Handshake is slow (>200ms)

4. Cipher Performance
   aes256-gcm: 850 MB/s
   chacha20-poly1305: 1200 MB/s
   ✓ Recommendation: Use chacha20-poly1305

5. Compression
   Without compression: 45 MB/s
   With compression: 38 MB/s
   ✓ Compression not helpful for this connection

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Recommendations:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Add to ~/.ssh/config:
   Host jupiter
     HostName 192.168.1.50
     Ciphers chacha20-poly1305@openssh.com
     Compression no

2. Add to /etc/hosts:
   192.168.1.50 jupiter
```

**When to use**:

- SSH connections feel sluggish
- After network changes
- When troubleshooting remote development
- Before configuring SSH multiplexing

---

#### `test-ssh-performance.sh`

**Integration**: standalone diagnostic tool
**Purpose**: Comprehensive SSH performance benchmarking

**Usage**:

```bash
./scripts/diagnostics/test-ssh-performance.sh [user@]hostname [port]
```

**Examples**:

```bash
# Basic benchmark
./scripts/diagnostics/test-ssh-performance.sh jupiter

# Full benchmark with all ciphers
./scripts/diagnostics/test-ssh-performance.sh jupiter --all-ciphers

# Compare compression
./scripts/diagnostics/test-ssh-performance.sh jupiter --test-compression
```

**Benchmarks**:

1. **Connection time** - How long to establish connection
2. **Throughput** - Data transfer speed (upload/download)
3. **Cipher performance** - Speed of different encryption algorithms
4. **Compression impact** - Throughput with/without compression
5. **Interactive latency** - Response time for keystrokes
6. **File transfer speed** - Real-world scp/sftp performance

**Output Example**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 SSH Performance Benchmark: jupiter
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Connection Time: 180ms
Ping Latency: 2.3ms

Cipher Performance (MB/s):
  aes256-gcm@openssh.com:           850 MB/s
  chacha20-poly1305@openssh.com:    1200 MB/s ⭐ FASTEST
  aes128-gcm@openssh.com:           920 MB/s

Throughput:
  Download: 980 MB/s
  Upload:   920 MB/s

Compression Impact:
  Without: 980 MB/s
  With:    780 MB/s
  Verdict: Disable compression (-20%)

File Transfer (100MB test file):
  scp:   8.5s (11.8 MB/s)
  sftp:  8.2s (12.2 MB/s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Optimal SSH Config:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Host jupiter
  HostName 192.168.1.50
  Ciphers chacha20-poly1305@openssh.com
  Compression no
  ControlMaster auto
  ControlPath ~/.ssh/control-%r@%h:%p
  ControlPersist 10m
```

**When to use**:

- Optimizing SSH configuration
- Comparing different network paths
- Validating performance improvements
- Benchmarking after system upgrades

---

### Audio Diagnostics

#### `diagnose-steam-audio.sh`

**Integration**: standalone diagnostic tool
**Purpose**: Comprehensive diagnostic tool for Steam/Proton audio issues with PipeWire

**Usage**:

```bash
# Run diagnostics (Steam can be running or stopped)
./scripts/diagnostics/diagnose-steam-audio.sh
```

**Diagnoses**:

1. **PipeWire Services** - PipeWire, PipeWire-Pulse, WirePlumber status
2. **PulseAudio Socket** - Socket existence and permissions
3. **Audio Sinks** - Available audio output devices in PipeWire
4. **Default Sink** - Properly configured default output
5. **WirePlumber Devices** - Device manager state
6. **Steam Environment** - Steam process audio environment variables
7. **Session Environment** - User session audio configuration
8. **Audio Playback** - Test audio output

**Output Example**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔊 Steam Audio Diagnostics
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. PipeWire Services
   pipewire:         ✓ active (running)
   pipewire-pulse:   ✓ active (running)
   wireplumber:      ✓ active (running)

2. PulseAudio Socket
   /run/user/1000/pulse/native: ✓ exists
   Permissions: srwxr-xr-x (correct)

3. Available Audio Sinks
   ✓ alsa_output.pci-0000_2b_00.4.analog-stereo (default)
     - Description: Starship/Matisse HD Audio Controller
     - State: RUNNING

4. Default Sink
   ✓ Default sink configured
   Name: alsa_output.pci-0000_2b_00.4.analog-stereo

5. Steam Environment
   PULSE_SERVER: unix:/run/user/1000/pulse/native ✓
   SDL_AUDIODRIVER: pulseaudio ✓

6. Audio Test
   ✓ Test audio played successfully

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary: All audio systems operational ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If games still have no audio, try:
1. Restart Steam: steam -shutdown && steam
2. Add to game launch options: SDL_AUDIODRIVER=pulseaudio %command%
```

**Common Issues Diagnosed**:

- **Games don't appear in audio mixer**
  - Missing `SDL_AUDIODRIVER=pulseaudio`
  - Wrong `PULSE_SERVER` path
- **No sound in games but other apps work**
  - Games using ALSA directly instead of PulseAudio
  - Missing PipeWire-Pulse bridge
- **Intermittent audio failures**
  - No explicit default sink configured in WirePlumber
  - Steam environment not properly set

**Fixes Suggested**:

1. Restart Steam: `steam -shutdown && steam`
2. Add to game launch options: `SDL_AUDIODRIVER=pulseaudio %command%`
3. Check Steam logs: `~/.local/share/Steam/logs/`
4. Enable debug logging: `PULSE_LOG=99 <game>`

**When to use**:

- Games have no audio but system audio works
- Games don't appear in audio mixer (pavucontrol/pwvucontrol)
- Audio works for some games but not others
- After PipeWire or Steam updates
- After switching audio devices

---

## Common Workflows

### 1. Diagnose Slow SSH Connection

```bash
# Step 1: Quick diagnosis
./scripts/diagnostics/diagnose-ssh-slowness.sh jupiter

# Step 2: Identify bottleneck from output
# - DNS slow? Add to /etc/hosts
# - Handshake slow? Check host key types
# - Cipher slow? Switch cipher

# Step 3: Apply recommendations to ~/.ssh/config
vim ~/.ssh/config

# Step 4: Benchmark improvement
./scripts/diagnostics/test-ssh-performance.sh jupiter
```

### 2. Optimize SSH Performance

```bash
# Step 1: Baseline benchmark
./scripts/diagnostics/test-ssh-performance.sh jupiter > baseline.txt

# Step 2: Apply recommended config
# (from benchmark output)

# Step 3: Compare
./scripts/diagnostics/test-ssh-performance.sh jupiter > optimized.txt
diff baseline.txt optimized.txt

# Step 4: Test real-world usage
ssh jupiter "cd project && git status"  # Should feel snappy
```

### 3. Fix Steam Audio Issues

```bash
# Step 1: Run diagnostics
./scripts/diagnostics/diagnose-steam-audio.sh

# Step 2: Apply fixes from output
# Example: Add SDL_AUDIODRIVER to game launch options

# Step 3: Test game audio
# Launch game and check audio mixer (pwvucontrol)

# Step 4: If still broken, check Steam logs
cat ~/.local/share/Steam/logs/bootstrap_log.txt
```

---

## SSH Configuration Examples

### Optimal ~/.ssh/config

Based on diagnostic results, here's a typical optimal config:

```ssh-config
# Global defaults
Host *
  # Connection multiplexing (reuse connections)
  ControlMaster auto
  ControlPath ~/.ssh/control-%r@%h:%p
  ControlPersist 10m

  # Fast cipher (modern CPUs)
  Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com

  # Fast key exchange
  KexAlgorithms curve25519-sha256@libssh.org

  # Disable compression (fast LAN)
  Compression no

  # Keep connections alive
  ServerAliveInterval 60
  ServerAliveCountMax 3

# Host-specific (from diagnose-ssh-slowness.sh output)
Host jupiter
  HostName 192.168.1.50
  User lewis

Host mercury
  HostName 192.168.1.51
  User lewis
```

### Connection Multiplexing Benefits

**Without multiplexing**:

- Each git/ssh command creates new connection (180ms)
- `git status` = 200ms+ per command

**With multiplexing**:

- First connection: 180ms
- Subsequent commands: <10ms (reuse existing connection)
- `git status` = 20ms per command

**Test multiplexing**:

```bash
# First connection (slow)
time ssh jupiter "echo test1"  # 180ms

# Reuses connection (fast)
time ssh jupiter "echo test2"  # 15ms
time ssh jupiter "echo test3"  # 15ms
```

---

## Troubleshooting

### SSH diagnostics show high latency but ping is fast

**Possible causes**:

1. SSH daemon is overloaded
2. Host key verification is slow (large known_hosts file)
3. PAM modules causing delays

**Check**:

```bash
# Test DNS
time nslookup jupiter

# Test raw connection
time nc -zv jupiter 22

# Test with verbose output
ssh -vvv jupiter
```

### Audio diagnostics show everything OK but no sound

**Check**:

1. Volume levels: `wpctl status` or `pwvucontrol`
2. Muted outputs: `wpctl set-mute @DEFAULT_SINK@ 0`
3. Game-specific audio settings
4. Steam launch options: Right-click game → Properties → Launch Options

**Debug**:

```bash
# Check PipeWire graph
pw-cli dump

# Monitor audio streams
pw-top

# Test audio directly
paplay /usr/share/sounds/alsa/Front_Center.wav
```

---

## Dependencies

Required packages:

- `openssh` - SSH client
- `iputils` - ping, nc
- `dnsutils` - nslookup, dig
- `pipewire` - Audio server
- `wireplumber` - Audio session manager
- `pipewire-pulse` - PulseAudio compatibility

Install missing dependencies:

```bash
nix-shell -p openssh iputils dnsutils pipewire wireplumber
```

---

## See Also

- [Network Scripts](../network/README.md) - Speed testing, MTU optimization
- [SSH Performance Tuning](../../docs/PERFORMANCE_TUNING.md#ssh-optimization)
- [Audio Setup](../../home/nixos/hardware-tools/audio.nix) - PipeWire configuration
- [Steam Configuration](../../modules/nixos/features/gaming.nix) - Gaming setup
