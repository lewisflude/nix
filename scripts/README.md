# Utility Scripts

This directory contains specialized diagnostic and automation scripts for this Nix configuration.

## qBittorrent Diagnostics & Management

### `diagnose-qbittorrent-seeding.sh` (299 lines)

Comprehensive diagnostic tool for qBittorrent seeding issues with ProtonVPN integration.

**Features:**
- Service status checking
- VPN namespace verification
- Port binding analysis
- qBittorrent API calls for configuration checking
- Firewall rule verification
- TCP/UDP/ICMP connectivity tests
- Actionable troubleshooting recommendations

**Usage:**
```bash
./scripts/diagnose-qbittorrent-seeding.sh
```

### `test-qbittorrent-seeding-health.sh` (395 lines)

Full health check system with detailed metrics and API integration.

**Features:**
- Upload ratio calculations
- Per-torrent statistics
- Tracker error detection
- Seeding torrent analysis
- Structured pass/fail/warning output

**Usage:**
```bash
./scripts/test-qbittorrent-seeding-health.sh
```

### `test-qbittorrent-connectivity.sh` (153 lines)

Focused network connectivity verification for qBittorrent.

**Features:**
- TCP/UDP connectivity tests
- Port binding validation
- Routing verification
- VPN namespace checks

**Usage:**
```bash
./scripts/test-qbittorrent-connectivity.sh
```

### `update-qbittorrent-protonvpn-port.sh` (175 lines)

Automated port updating for qBittorrent based on ProtonVPN port forwarding.

**Features:**
- NAT-PMP port detection
- qBittorrent API configuration updates
- Firewall rule updates (iptables)
- Fallback to manual discovery instructions

**Usage:**
```bash
./scripts/update-qbittorrent-protonvpn-port.sh
```

## ProtonVPN Port Forwarding

### `get-protonvpn-forwarded-port.sh` (57 lines)

Simple NAT-PMP based port detection for ProtonVPN.

**Usage:**
```bash
./scripts/get-protonvpn-forwarded-port.sh
```

### `find-protonvpn-forwarded-port.sh` (77 lines)

Port scanning tool to find the correct forwarded port.

**Features:**
- Tests multiple port ranges (6881-6890, 49152-49160, 50000-50004)
- Provides manual instructions as fallback

**Usage:**
```bash
./scripts/find-protonvpn-forwarded-port.sh
```

### `test-protonvpn-port-forwarding.sh` (97 lines)

Tests if a specific port is accessible externally.

**Features:**
- Uses yougetsignal.com API for external port checking
- Verifies which port qBittorrent is actually listening on

**Usage:**
```bash
./scripts/test-protonvpn-port-forwarding.sh [PORT]
```

## SSH Performance & Diagnostics

### `test-ssh-performance.sh` (217 lines)

Comprehensive SSH performance benchmarking tool.

**Features:**
- Connection timing tests
- Authentication latency measurement
- Connection multiplexing/reuse testing
- Command execution latency (10 samples with min/max/avg)
- Ping latency analysis
- Performance grading (Excellent/Good/Acceptable/Slow)
- ControlMaster socket checking

**Usage:**
```bash
./scripts/test-ssh-performance.sh <hostname>
```

### `diagnose-ssh-slowness.sh` (104 lines)

SSH connection troubleshooting focused on identifying bottlenecks.

**Features:**
- DNS resolution timing
- Verbose connection analysis
- Optimization recommendations
- Comparison of default vs optimized SSH options

**Usage:**
```bash
./scripts/diagnose-ssh-slowness.sh <hostname>
```

## Network Speed Testing

### `test-vlan2-speed.sh` (243 lines)

Detailed network speed testing specifically for VLAN 2.

**Features:**
- Download speed testing (multiple test files, averaged results)
- Upload speed testing (10MB file to httpbin.org)
- Latency measurements
- Gateway connectivity verification
- DNS resolution tests
- Performance grading

**Usage:**
```bash
./scripts/test-vlan2-speed.sh
```

### `test-sped.sh` (33 lines)

Simple wrapper for speed testing tools.

**Features:**
- speedtest-cli integration
- fast.com speed test
- Basic port connectivity check

**Usage:**
```bash
./scripts/test-sped.sh
```

**Note:** This is a minimal wrapper with limited error handling.

## Script Workflows

### qBittorrent Seeding Issues

1. Start with `diagnose-qbittorrent-seeding.sh` for comprehensive overview
2. Use `test-qbittorrent-seeding-health.sh` for detailed metrics
3. If port issues found, run `update-qbittorrent-protonvpn-port.sh`
4. Verify with `test-qbittorrent-connectivity.sh`

### ProtonVPN Port Discovery

1. Try `get-protonvpn-forwarded-port.sh` for quick NAT-PMP detection
2. If that fails, use `find-protonvpn-forwarded-port.sh` to scan ranges
3. Verify port is externally accessible with `test-protonvpn-port-forwarding.sh`

### SSH Connection Problems

1. Run `diagnose-ssh-slowness.sh` first to identify issues
2. Use `test-ssh-performance.sh` for detailed benchmarking
3. Apply recommendations from diagnostics

## Dependencies

These scripts require various system tools:

- **curl** - HTTP requests
- **jq** - JSON parsing (implicit in some scripts)
- **systemctl** - systemd service management
- **ip** - Network namespace/interface management
- **iptables** - Firewall management
- **ss** - Socket statistics
- **nc/netcat** - UDP connectivity testing
- **ping** - ICMP connectivity
- **natpmpc** - NAT-PMP port mapping (optional)
- **speedtest-cli**, **fast-cli** - Speed testing
- **dig** - DNS resolution
- **bc** - Mathematical calculations

All dependencies are typically included in NixOS configurations.

## Notes

- Most scripts require sudo/root permissions for network namespace operations
- Scripts are designed for NixOS with systemd
- qBittorrent scripts assume service is running in VPN network namespace
- Color output is used throughout for better readability
