# Organizing Music Production Torrents

This guide explains how to reorganize your music production downloads into subfolders while maintaining torrent tracking in both qBittorrent and Transmission.

## Overview

You have ~95 music production items in `/mnt/storage/torrents` that need to be organized into categories like:

```
/mnt/storage/torrents/music-production/
├── daw-software/
├── plugins/
│   ├── synthesizers/
│   ├── effects/
│   └── mixing-mastering/
├── sample-packs/
│   ├── jungle-dnb/
│   ├── elektron-rytm/
│   ├── drums/
│   └── other/
├── presets/
│   ├── serum/
│   ├── fabfilter/
│   ├── kick/
│   ├── vintage-synths/
│   └── other/
├── ableton-racks/
├── midi-packs/
├── tutorials/
└── uncategorized/
```

## Methods

### Method 1: Automated Script (Recommended)

We've created a script that automatically categorizes and moves torrents using the APIs.

#### Setup

1. **Configure authentication** (if needed):

```bash
export QBIT_USER="your_username"
export QBIT_PASS="your_password"
export TRANS_USER="your_username"
export TRANS_PASS="your_password"
```

2. **Test with dry-run** (see what would happen):

```bash
./scripts/media/organize-music-production-torrents.sh --dry-run
```

3. **Run for real**:

```bash
# Move torrents in both clients
./scripts/media/organize-music-production-torrents.sh

# Or just one client
./scripts/media/organize-music-production-torrents.sh --client qbittorrent
./scripts/media/organize-music-production-torrents.sh --client transmission
```

#### How It Works

The script:
1. Creates the folder structure on jupiter
2. Connects to qBittorrent/Transmission APIs
3. Gets list of torrents in `/mnt/storage/torrents`
4. Detects category based on torrent name patterns
5. Uses the API to move torrents (maintains tracking)
6. Reports what was moved

### Method 2: qBittorrent WebUI (Manual)

#### Option A: Individual Torrents

1. Open qBittorrent WebUI: `http://jupiter:8070`
2. Select torrent(s) (Ctrl/Cmd+Click for multiple)
3. Right-click → **"Set location..."**
4. Browse to: `/mnt/storage/torrents/music-production/<category>/`
5. Click OK

#### Option B: Using Categories

1. **Create categories**:
   - Right-click in Categories pane
   - Add new categories with paths:
     - `music-prod-daw` → `/mnt/storage/torrents/music-production/daw-software`
     - `music-prod-synths` → `/mnt/storage/torrents/music-production/plugins/synthesizers`
     - `music-prod-samples` → `/mnt/storage/torrents/music-production/sample-packs/jungle-dnb`
     - etc.

2. **Assign torrents**:
   - Select torrent(s)
   - Right-click → **"Set category"**
   - Choose category
   - qBittorrent will automatically move files to category path

### Method 3: Transmission WebUI (Manual)

1. Open Transmission WebUI: `http://jupiter:9091`
2. Select torrent(s)
3. Click **gear icon** (⚙️) or right-click
4. Select **"Set Location..."**
5. Enter new path: `/mnt/storage/torrents/music-production/<category>/`
6. Check **"Move files"** (not just update location)
7. Click OK

### Method 4: transmission-remote CLI

```bash
# List torrents
transmission-remote jupiter:9091 --list

# Move a torrent
transmission-remote jupiter:9091 \
  --torrent <ID> \
  --move /mnt/storage/torrents/music-production/<category>/
```

## Category Mapping

The automated script uses these patterns to detect categories:

| Pattern | Category |
|---------|----------|
| Ableton, Logic, FL Studio, Cubase, Reaper, Studio One, Pro Tools, Bitwig | `daw-software` |
| Serum, Massive, Omnisphere, Diva, Pigments, Vital, JUP-8, M1, DX7, TX81Z | `plugins/synthesizers` |
| FabFilter, Waves, iZotope, Soundtoys, Valhalla, Goodhertz, AudioThing, Aphex | `plugins/effects` |
| Melodyne, Auto-Tune, Ozone, Neutron, RX | `plugins/mixing-mastering` |
| Jungle, Amen, Breakbeat, DnB, Drum and Bass | `sample-packs/jungle-dnb` |
| Elektron Analog Rytm | `sample-packs/elektron-rytm` |
| Superior Drummer, GetGood Drums, Toontrack Drum | `sample-packs/drums` |
| Serum Preset | `presets/serum` |
| FabFilter Preset | `presets/fabfilter` |
| KICK Preset | `presets/kick` |
| DX7/TX81Z/JUP-8000 CARTRIDGE/BANK | `presets/vintage-synths` |
| ABLETON RACK, iFeature | `ableton-racks` |
| .MiDi, MIDI, Toontrack | `midi-packs` |
| Groove3, TUTORIAL | `tutorials` |
| Everything else | `uncategorized` |

## Safety Tips

1. **Always test with --dry-run first** to see what will happen
2. **Backup torrent session data** before bulk operations:
   ```bash
   ssh jupiter "tar -czf ~/qbittorrent-backup.tar.gz /var/lib/qbittorrent/.config"
   ssh jupiter "tar -czf ~/transmission-backup.tar.gz /var/lib/transmission/.config"
   ```
3. **Don't manually move files** - always use the API or WebUI "Set location" feature
4. **Check seeding status** after moving to ensure everything still works

## Verification

After organizing, verify torrents are still tracked:

```bash
# qBittorrent
./scripts/diagnose-qbittorrent-seeding.sh

# Check Transmission
transmission-remote jupiter:9091 --list
```

## Troubleshooting

### "Torrent not found" after moving

This shouldn't happen with the API methods, but if it does:
1. Stop the client
2. Manually move files back to original location
3. Start the client
4. Try again using the WebUI/API method

### "Permission denied" on new folders

```bash
ssh jupiter "chown -R media:media /mnt/storage/torrents/music-production"
ssh jupiter "chmod -R 775 /mnt/storage/torrents/music-production"
```

### API authentication fails

For qBittorrent, get credentials from SOPS:
```bash
ssh jupiter "cat /run/secrets/qbittorrent/webui/username"
ssh jupiter "cat /run/secrets/qbittorrent/webui/password"
```

For Transmission:
```bash
ssh jupiter "cat /run/secrets/transmission/rpc/username"
ssh jupiter "cat /run/secrets/transmission/rpc/password"
```

## Manual Category Assignment (If Script Misses Some)

The script puts unrecognized items in `uncategorized/`. To manually categorize:

1. Check what's uncategorized:
   ```bash
   ssh jupiter "ls -la /mnt/storage/torrents/music-production/uncategorized/"
   ```

2. Move using WebUI or CLI as described above

## Additional Resources

- qBittorrent API: <https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)>
- Transmission RPC: <https://github.com/transmission/transmission/blob/main/docs/rpc-spec.md>
