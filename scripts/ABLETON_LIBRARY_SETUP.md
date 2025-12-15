# Ableton Library Professional Setup Guide

## Overview

This guide implements a **Tiered Library Architecture** for professional Ableton Live workflow, balancing performance, portability, and capacity.

## Philosophy: The 80/20 Rule

**80% of your production uses 20% of your library.** That critical 20% lives on internal storage for performance and portability.

---

## Architecture

### 📱 Tier 1: Internal MacBook (Performance Layer)
- **Location:** `/Users/lewisflude/Music/Ableton/User Library/`
- **Purpose:** Always available, fast access to essentials
- **Target Size:** 5-10GB
- **Contents:**
  - ✅ Defaults and preferences
  - ✅ Project templates
  - ✅ Top 20% most-used presets
  - ✅ Essential MIDI clips and patterns
  - ✅ Grooves and MIDI tools

### 💾 Tier 2: Samsung Drive (Expansion Layer)
- **Location:** `/Volumes/Samsung Drive/Ableton/`
- **Purpose:** Bulk storage accessible via Ableton's "Places"
- **Structure:**
  ```
  /Volumes/Samsung Drive/Ableton/
  ├── Sample Libraries/          # Large multi-GB sample packs
  ├── Presets-Extended/         # Full preset collections
  ├── Factory Packs/            # Official Ableton packs
  ├── Projects-Active/          # Current working projects
  ├── Projects-Archive/         # Completed projects
  ├── Sound Design Sources/     # Raw materials
  └── Tutorials/                # Learning materials
  ```

---

## Benefits

| Aspect | Benefit |
|--------|---------|
| **Portability** | Core library works without external drive |
| **Performance** | Fast internal NVMe access for common tasks |
| **Capacity** | Bulk content available when Samsung connected |
| **Reliability** | Graceful degradation if drive unavailable |
| **Scalability** | Easy to add more external locations |
| **Professional** | Matches industry studio standards |

---

## Installation

### Step 1: Audit Current State

```bash
./scripts/ableton-library-audit.sh
```

This will analyze your current setup and show:
- MacBook User Library size and contents
- Samsung Drive status and organization
- Available storage space
- Recommendations for library size

### Step 2: Run Migration

```bash
./scripts/ableton-library-migrate.sh
```

This automated script will:
1. ✅ Backup your current MacBook User Library
2. ✅ Reorganize Samsung Drive with clear structure
3. ✅ Create a curated internal User Library
4. ✅ Move compressed archives to Samsung Drive
5. ✅ Generate documentation in both locations

**Safety:** Creates timestamped backup before making any changes.

### Step 3: Configure Ableton Live

1. **Open Ableton Live**

2. **Go to Preferences → Library**

3. **Set User Library:**
   - Click "Choose Folder"
   - Select: `/Users/lewisflude/Music/Ableton/User Library/`
   - Click "Use Folder"

4. **Add Places (external locations):**
   - In the "Places" section, click "Add Folder"
   - Add these locations:
     - `/Volumes/Samsung Drive/Ableton/Sample Libraries`
     - `/Volumes/Samsung Drive/Ableton/Presets-Extended`
     - `/Volumes/Samsung Drive/Ableton/Factory Packs`

5. **Click OK** to save settings

### Step 4: Curate Your Internal Library

The migration creates the structure, but you need to populate it with your essentials:

1. **Browse Samsung's archived content:**
   ```bash
   open "/Volumes/Samsung Drive/Ableton/User Library-Full"
   ```

2. **Identify your most-used presets:**
   - Think about what you reach for in 80% of your projects
   - Check your recent projects to see what presets are referenced

3. **Copy essentials to internal storage:**
   ```bash
   # Example: Copy your favorite synth presets
   cp -R "/Volumes/Samsung Drive/Ableton/User Library-Full/Presets/Instruments/Serum/MyFavorites" \
         "/Users/lewisflude/Music/Ableton/User Library/Presets/Instruments/Serum/"
   ```

4. **Keep it lean - aim for 5-10GB total**

### Step 5: Test the Setup

1. **Test with Samsung Drive connected:**
   - Open Ableton Live
   - Verify you can see content from both locations
   - Check that "Places" folders appear in browser

2. **Test without Samsung Drive:**
   - Eject Samsung Drive
   - Open Ableton Live
   - Verify essential templates and presets still load
   - Confirm Ableton doesn't throw errors

3. **Reconnect and verify:**
   - Connect Samsung Drive
   - Open Ableton Live
   - Confirm additional content reappears

---

## Maintenance

### Regular Health Checks

Run monthly to monitor library health:

```bash
./scripts/ableton-library-health.sh
```

This shows:
- ✅ Health score (0-100)
- ✅ Internal library size check
- ✅ Samsung Drive connectivity
- ✅ Large file detection
- ✅ Optimization recommendations

### Keep Internal Library Lean

**Monitor size:**
```bash
du -sh "/Users/lewisflude/Music/Ableton/User Library"
```

**Find large files to move:**
```bash
find "/Users/lewisflude/Music/Ableton/User Library" -type f -size +50M -exec ls -lh {} \;
```

**Clean up metadata:**
```bash
find "/Users/lewisflude/Music/Ableton/User Library" -name '.DS_Store' -delete
```

### When to Move Content

**Move to Samsung Drive if:**
- ❌ File is over 100MB
- ❌ Haven't used in 3+ months
- ❌ It's a full sample library (multi-GB)
- ❌ It's tutorial or learning content
- ❌ It's a completed project

**Keep on internal if:**
- ✅ Used weekly or more
- ✅ Part of your default template
- ✅ Small file size (<10MB)
- ✅ Critical to your workflow
- ✅ Active project you're working on

---

## Workflow Best Practices

### Starting a New Project

1. Create from internal template (fast load)
2. Save to internal storage during active work
3. Add samples from Samsung "Places" as needed
4. When complete, move to Samsung's Projects-Archive/

### Managing Presets

**Internal storage (essential presets):**
- Your signature sounds
- Go-to starting points
- Utility presets (reference tones, etc.)

**Samsung Drive (extended collection):**
- Full preset packs
- Experimental presets
- Genre-specific collections you use occasionally

### Sample Library Organization

**Samsung Drive structure:**
```
/Volumes/Samsung Drive/Ableton/Sample Libraries/
├── Drums/
│   ├── Kicks/
│   ├── Snares/
│   └── Percussion/
├── Bass/
├── Synths/
├── FX/
└── Vocals/
```

Add the top-level "Sample Libraries" folder to Ableton's Places, and you'll have organized access to everything.

---

## Troubleshooting

### Ableton Shows "File Not Found" Errors

**Cause:** Samsung Drive not connected or library path changed

**Solution:**
1. Connect Samsung Drive
2. If still broken, check Preferences → Library → Places
3. Re-add Samsung Drive locations if needed

### Internal Library Growing Too Large

**Solution:**
```bash
# Run health check
./scripts/ableton-library-health.sh

# Find large files
find "/Users/lewisflude/Music/Ableton/User Library" -type f -size +50M

# Move them to Samsung Drive
mv [large-file] "/Volumes/Samsung Drive/Ableton/Sample Libraries/"
```

### Can't Find Content in Ableton

**Check:**
1. Is Samsung Drive connected?
2. Are Places configured correctly? (Preferences → Library → Places)
3. Is the content in the right location?
4. Try refreshing browser (right-click → Refresh)

### Want to Work Portable (Without Samsung Drive)

**Temporary solution:**
1. Copy specific projects to internal storage
2. Copy any required samples to internal User Library
3. Work portable
4. Sync back to Samsung when reconnected

**Permanent solution:**
- Ensure all essential presets are on internal storage
- Use cloud-stored projects (Dropbox, etc.) for access anywhere
- Consider a second portable SSD for travel

---

## Migration from Old Setup

If you previously had everything on Samsung Drive:

1. **Run migration script** - creates new structure
2. **Test Ableton** - verify it works with new paths
3. **Delete old backup** - only after confirming everything works:
   ```bash
   # ONLY after testing thoroughly
   rm -rf "/Volumes/Samsung Drive/Ableton/Ableton-OLD-BACKUP"
   ```

---

## Advanced: Automation

### Auto-mount Samsung Drive on Login (macOS)

1. Open **System Settings** → **General** → **Login Items**
2. Add Samsung Drive to automatically reconnect at login

### Sync Active Projects

Use `rsync` to sync active projects between internal and Samsung:

```bash
# Backup active project to Samsung
rsync -av --progress \
  "/Users/lewisflude/Music/Ableton/Projects/MyProject/" \
  "/Volumes/Samsung Drive/Ableton/Projects-Active/MyProject/"
```

### Monitor Storage Usage

Add to your shell profile (`~/.zshrc`):

```bash
alias ableton-size='du -sh "/Users/lewisflude/Music/Ableton/User Library" && df -h /Users'
```

---

## Support

### Scripts Included

| Script | Purpose |
|--------|---------|
| `ableton-library-audit.sh` | Analyze current state |
| `ableton-library-migrate.sh` | Automated migration |
| `ableton-library-health.sh` | Ongoing health monitoring |

### Documentation

- **Internal Library README:** `/Users/lewisflude/Music/Ableton/User Library/README.md`
- **Samsung Drive README:** `/Volumes/Samsung Drive/Ableton/README.md`
- **This Guide:** `./scripts/ABLETON_LIBRARY_SETUP.md`

### Getting Help

If you encounter issues:

1. Run health check: `./scripts/ableton-library-health.sh`
2. Check Ableton's preferences: Preferences → Library
3. Verify Samsung Drive is mounted: `ls /Volumes/`
4. Check backup exists: `ls ~/Music/Ableton/Backup-*`

---

## Summary

This setup gives you:
- ✅ **Professional workflow** matching industry standards
- ✅ **Fast performance** with internal storage for essentials
- ✅ **Portability** - works without external drive
- ✅ **Scalability** - easy to expand storage
- ✅ **Reliability** - graceful degradation
- ✅ **Organization** - clear, maintainable structure

**Key principle:** Keep internal storage lean and curated, use external for bulk content via "Places".
