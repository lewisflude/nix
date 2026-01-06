# Audio Routing Logic Diagram

## Decision Tree

```
Application Starts
│
├─ Is it a Gaming Application?
│  │
│  ├─ YES → Matches: steam, gamescope, wine*, *.exe
│  │  │
│  │  └─→ AUTOMATIC ROUTING
│  │     └─→ input.apogee_stereo_game_bridge
│  │        (Priority: 1900, Latency: gamingLatency)
│  │        │
│  │        └─→ Routes to: alsa_output.usb-Apogee_...pro-output-0
│  │           (Physical Apogee Symphony Desktop - Stereo channels only)
│  │
│  └─ NO → Continue to Priority Selection
│
└─ Priority-Based Sink Selection (Highest Priority Wins)
   │
   ├─ Priority 1000: Other ALSA outputs (generic)
   │  └─→ Any alsa_output.* (except Apogee)
   │     Currently: None active (HDMI disabled)
   │
   ├─ Priority 100: alsa_output.usb-Apogee_...pro-output-0
   │  └─→ Apogee Symphony Desktop Pro (direct)
   │     Status: RUNNING
   │     Format: s32le, 10ch, 48kHz
   │     Use Case: **Default for regular apps** (direct connection, no bridge)
   │
   ├─ Priority 50: input.apogee_stereo_game_bridge
   │  └─→ Virtual stereo bridge (routes to Apogee)
   │     Status: RUNNING
   │     Format: float32le, 2ch, 48kHz
   │     Use Case: **Gaming only** (forced via stream rules, not auto-selected)
   │
   ├─ Priority 1: Intel PCH Built-in Audio
   │  └─→ alsa_card.pci-0000_00_1f.3
   │     Status: Backup (very low priority)
   │     Use Case: Emergency fallback only
   │
   └─ DISABLED: NVIDIA AD102 HDMI Audio
      └─→ alsa_card.pci-0000_01_00.1
         Status: device.disabled = true
         Use Case: Never used (removed from selection)
```

## Detailed Routing Scenarios

### Scenario 1: Gaming Application (Steam, Gamescope, Wine)

```
Application: steam / gamescope / wine* / *.exe
│
└─→ WirePlumber Rule Match: "90-gaming-routing"
   │
   └─→ FORCED ROUTE: input.apogee_stereo_game_bridge
      │
      ├─ Virtual Sink Properties:
      │  • Priority: 1900 (highest)
      │  • Latency: gamingLatency (512 frames @ 48kHz = ~10.7ms)
      │  • Channels: Stereo (FL, FR)
      │  • Format: float32le
      │
      └─→ Physical Output: alsa_output.usb-Apogee_...pro-output-0
         • Only uses stereo channels (FL, FR)
         • Prevents multi-channel issues in games/Proton
         • stream.dont-remix = true (no channel remixing)
```

### Scenario 2: Regular Desktop Application

```
Application: Browser, Media Player, etc.
│
└─→ Default Sink Selection (Priority-based)
   │
   ├─ Check: alsa_output.usb-Apogee_...pro-output-0 (Priority: 100)
   │  └─→ SELECTED (highest priority for regular apps)
   │     └─→ Direct Apogee connection (no bridge overhead)
   │
   ├─ Fallback: Generic ALSA outputs (Priority: 1000)
   │  └─→ Other audio devices (if Apogee unavailable)
   │
   ├─ Bridge: input.apogee_stereo_game_bridge (Priority: 50)
   │  └─→ NOT selected (lower priority, only for games)
   │
   └─ Last Resort: Intel PCH (Priority: 1)
      └─→ Only if Apogee not connected
```

### Scenario 3: Professional Audio Application

```
Application: Ardour, REAPER, Bitwig, etc.
│
└─→ Can explicitly select: alsa_output.usb-Apogee_...pro-output-0
   │
   └─→ Direct multi-channel access (10 channels)
      • No stereo bridge limitation
      • Full professional audio interface capabilities
      • JACK support enabled (services.pipewire.jack.enable = true)
```

### Scenario 4: Bluetooth Audio Device

```
Bluetooth Device Connected
│
└─→ WirePlumber BlueZ Rules
   │
   ├─ Codecs Available (priority order):
   │  • LDAC (high quality)
   │  • aptX HD
   │  • aptX
   │  • AAC
   │  • SBC XQ
   │  • SBC
   │
   └─→ Auto-selected when:
      • Device connected and paired
      • Higher priority than default sinks
      • Uses A2DP profile
```

## Priority Summary Table

| Sink/Device | Priority | Status | Auto-Select | Use Case |
|------------|----------|--------|-------------|----------|
| Generic ALSA outputs | 1000 | N/A | ✅ Yes | Fallback |
| `alsa_output.usb-Apogee_...pro-output-0` | 100 | RUNNING | ✅ Yes | **Default for regular apps** |
| `input.apogee_stereo_game_bridge` | 50 | RUNNING | ❌ No | **Gaming only (forced via rules)** |
| Intel PCH Built-in | 1 | Backup | ❌ No | Emergency only |
| NVIDIA AD102 HDMI | Disabled | N/A | ❌ No | Never used |

## Automatic Routing Rules

### Gaming Applications (Forced Route)

```nix
Matches:
  • application.process.binary = "steam"
  • application.name = "~steam_app_.*"
  • application.name = "Steam"
  • application.id = "gamescope"
  • application.process.binary = "~wine.*"
  • application.process.binary = "~.*\\.exe"

Action:
  → node.target = "input.apogee_stereo_game_bridge"
  → node.latency = gamingLatency
  → session.suspend-timeout-seconds = 0
```

## Device Status

### Active Devices

- ✅ **Apogee Stereo Game Bridge** (Virtual) - Priority 1900
- ✅ **Apogee Symphony Desktop Pro** (Physical) - Priority 100

### Disabled Devices

- ❌ **NVIDIA AD102 HDMI** - Completely disabled

### Backup Devices

- ⚠️ **Intel PCH Built-in Audio** - Priority 1 (emergency only)

## Latency Settings

| Mode | Quantum | Latency | Use Case |
|------|---------|----------|----------|
| **Default** | 256 frames | ~5.3ms @ 48kHz | General use |
| **Gaming** | 512 frames | ~10.7ms @ 48kHz | Games (2x quantum for stability) |
| **Ultra-Low** | 64 frames | ~1.3ms @ 48kHz | Professional recording (disabled) |

## Key Configuration Points

1. **Gaming Bridge**: Virtual sink that presents stereo to games, routes to Apogee
2. **Priority System**: Higher priority = more likely to be auto-selected
3. **Automatic Routing**: Games are forced to use bridge (prevents multi-channel issues)
4. **HDMI Disabled**: NVIDIA HDMI completely removed from selection
5. **Backup Available**: Intel PCH kept at very low priority for emergencies

## Manual Override

Users can manually select any available sink:

```bash
# Switch to Apogee direct (multi-channel)
pactl set-default-sink alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0

# Switch to stereo bridge
pactl set-default-sink input.apogee_stereo_game_bridge

# Switch to Intel PCH (backup)
pactl set-default-sink alsa_output.pci-0000_00_1f.3.*
```

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Starts                       │
└───────────────────────┬─────────────────────────────────────┘
                        │
            ┌────────────┴────────────┐
            │                         │
      ┌─────▼─────┐           ┌──────▼──────┐
      │  Gaming   │           │   Regular   │
      │   App?    │           │    App?     │
      └─────┬─────┘           └──────┬──────┘
            │                         │
    ┌───────┴───────┐                │
    │               │                 │
   YES             NO                │
    │               │                 │
    │      ┌────────┴────────┐        │
    │      │                 │        │
    │   Priority Selection   │        │
    │      │                 │        │
    │      └────────┬────────┘        │
    │               │                 │
    └───────────────┼─────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
   Priority 1900          Priority 100
   (Stereo Bridge)      (Apogee Direct)
        │                       │
        └───────────┬───────────┘
                    │
        ┌───────────▼───────────┐
        │  Apogee Symphony      │
        │  Desktop Pro          │
        │  (Physical Output)    │
        └───────────────────────┘
```
