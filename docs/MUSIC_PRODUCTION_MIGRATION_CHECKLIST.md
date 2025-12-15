# Music Production Library Migration Checklist

Complete migration from Mac internal SSD to three-tier architecture:
- **Mac**: Essential presets/MIDI (no T7 errors)
- **T7**: Working library (portable)
- **NAS**: Deep archive (when home via gigabit ethernet)

---

## Pre-Migration

### ✅ Prerequisites

- [ ] **NAS mounted**: `/Volumes/storage` accessible
- [ ] **T7 connected**: `/Volumes/Samsung Drive` available
- [ ] **Ableton closed**: Quit all instances
- [ ] **Backup exists**: Current T7 has old backup (will be replaced)
- [ ] **Disk space checked**: Mac has 9GB free (will have 52GB after)

### ✅ Understand the Plan

**What stays on Mac (~2.7GB):**
- All presets (FabFilter, KICK, Serum, JUP-8000, DX7)
- All MIDI packs (Toontrack, GetGood)
- Ableton Racks (iFeature)
- Plugin installers
- Reference books

**What moves to T7 (~46GB):**
- Entire current Mac Ableton folder (44GB)
- XLNTSOUND Bass pack (1.5GB)
- Analog Rytm samples (99MB)
- Video tutorials (458MB)

**What stays on NAS (accessed when home):**
- Superior Drummer 3 (208GB)
- Samples From Mars (59GB)
- Everything else

---

## Phase 1: Copy Essentials to Mac

### 📋 Run Mac Migration Script

```bash
cd ~/.config/nix/scripts/media

# Test first
./migrate-music-production-mac.sh --dry-run

# Review output, then run for real
./migrate-music-production-mac.sh
```

**Expected time:** 10-15 minutes
**Expected size:** ~2.7GB copied

### ✅ Verify Mac Essentials

- [ ] Check: `~/Music/Ableton/User Library/Presets/`
  - [ ] Audio Effects/FabFilter/ (PRO-Q, PRO-R)
  - [ ] Instruments/KICK-3/ (10 preset packs)
  - [ ] Instruments/Serum/ (3 packs + XLNTSOUND)
  - [ ] Instruments/JUP-8000/
  - [ ] Instruments/DX7/ (already there)

- [ ] Check: `~/Music/Ableton/User Library/Presets/Audio Effects/Ableton/`
  - [ ] 6 iFeature racks

- [ ] Check: `~/Music/Ableton/User Library/Clips/MIDI/`
  - [ ] Drums/Toontrack/ (8 packs)
  - [ ] Keys/Toontrack/ (4 packs)
  - [ ] Drums/GetGood/ (1 pack)

- [ ] Check: `~/Music/Plugin Installers/macOS/`
  - [ ] 7 plugin installers

- [ ] Check: `~/Documents/Music Production/Books/`
  - [ ] Aphex Twin SAW Vol.II.epub

---

## Phase 2: Migrate to T7

### 📋 Run T7 Migration Script

```bash
cd ~/.config/nix/scripts/media

# Test first
./migrate-music-production-t7.sh --dry-run

# Review output, then run for real
./migrate-music-production-t7.sh
```

**Expected time:** 20-30 minutes (moving 44GB)
**Expected size:** ~46GB total on T7

### ✅ Verify T7 Contents

- [ ] Check: `/Volumes/Samsung Drive/Ableton/Factory Packs/` (28GB)
- [ ] Check: `/Volumes/Samsung Drive/Ableton/User Library/Sample Library/`
  - [ ] All jungle/DnB packs from Mac
  - [ ] Bass/XLNTSOUND Quest For Bass Vol.2/
  - [ ] Analog-Rytm/ (11 packs)
  - [ ] DX7, TX81Z (from Mac)

- [ ] Check: `/Volumes/Samsung Drive/Ableton/User Library/Tutorials/`
  - [ ] 2 Groove3 tutorials

- [ ] Check: `/Volumes/Samsung Drive/Projects/`
  - [ ] Active/
  - [ ] Archive/
  - [ ] Samples/

---

## Phase 3: Update Ableton Configuration

### 📋 Update Library Paths

```bash
cd ~/.config/nix/scripts/media

# Backup and update Ableton config
./update-ableton-library-paths.sh --dry-run
./update-ableton-library-paths.sh
```

### ✅ Configure Ableton Manually

- [ ] **Launch Ableton Live**

- [ ] **Go to**: `Preferences → Library`

- [ ] **Verify User Library Path**:
  - Should show: `/Volumes/Samsung Drive/Ableton`
  - If not, browse and select it

- [ ] **Add Secondary Folders to Index**:

  Click "+ Add Folder" and add:

  - [ ] `/Volumes/storage/torrents/music-production`
  - [ ] `/Volumes/storage/torrents`

- [ ] **Wait for indexing**: Let Ableton scan all locations

---

## Phase 4: Verify Everything Works

### ✅ Test Ableton with T7 Connected

- [ ] **Browser shows all content**
  - [ ] Factory Packs visible
  - [ ] User Library samples visible
  - [ ] NAS samples visible (if mounted)

- [ ] **Test loading**:
  - [ ] Load a FabFilter preset (from Mac)
  - [ ] Load a KICK preset (from Mac)
  - [ ] Drag a MIDI clip (from Mac)
  - [ ] Load a jungle sample (from T7)
  - [ ] Open XLNTSOUND project (from T7)

- [ ] **Create test project on T7**:
  - [ ] `File → Save Live Set As...`
  - [ ] Save to: `/Volumes/Samsung Drive/Projects/Active/`

### ✅ Test Ableton WITHOUT T7 (Important!)

- [ ] **Eject T7 drive**

- [ ] **Launch Ableton**

- [ ] **Verify no critical errors**:
  - [ ] FabFilter presets load ✓
  - [ ] KICK presets load ✓
  - [ ] Serum presets load ✓
  - [ ] MIDI clips load ✓
  - [ ] Ableton racks load ✓
  - [ ] T7 samples show "missing" (expected)
  - [ ] NAS samples show "missing" (expected)

- [ ] **Reconnect T7**

- [ ] **Relaunch Ableton**:
  - [ ] "Missing" samples now appear ✓

---

## Phase 5: Clean Up Mac

### ⚠️ CRITICAL: Only After Verification!

**DO NOT proceed until you've verified Phase 4 completely!**

- [ ] **Final verification checklist**:
  - [ ] T7 library fully functional ✓
  - [ ] Mac presets load without T7 ✓
  - [ ] NAS accessible when home ✓
  - [ ] Test project saved and reopened ✓

### 📋 Delete Mac Ableton Folder

```bash
# Check size one last time
du -sh ~/Music/Ableton
# Should show ~43GB

# ONLY if everything works:
rm -rf ~/Music/Ableton

# Verify space freed
df -h /
# Should now show ~52GB free instead of 9GB
```

### ✅ Post-Cleanup Verification

- [ ] Mac has ~52GB free space (was 9GB)
- [ ] Mac only contains essentials:
  - [ ] `~/Music/Ableton/User Library/Presets/`
  - [ ] `~/Music/Ableton/User Library/Clips/`
  - [ ] `~/Music/Plugin Installers/`

---

## Migration Complete! 🎉

All configuration files updated. Proceed to testing phase.