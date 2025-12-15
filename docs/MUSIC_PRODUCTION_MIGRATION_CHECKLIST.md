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

Wait... the scripts will only copy to Mac, not move the Mac Ableton folder. Let me reconsider this.

Actually, I think the strategy should be:

1. Copy essentials from NAS → Mac (new structure)
2. Move Mac's CURRENT Ableton folder → T7
3. Then Mac will only have the essentials we copied

Let me update the checklist to reflect this.

Actually wait, I need to reconsider the whole flow. The user's Mac currently has:
- `/Users/lewisflude/Music/Ableton/` (44GB)

This contains Factory Packs and User Library with samples.

The plan should be:
1. Copy NEW essentials from NAS → Mac (into User Library structure)
2. Move ENTIRE Mac Ableton folder → T7
3. This leaves only the newly copied essentials on Mac

But that means the essentials we copy need to go to a DIFFERENT location on Mac that won't get moved.

Actually, I think we should:
1. Move Mac Ableton → T7 FIRST
2. Then copy essentials from NAS AND T7 back to Mac

Let me revise the scripts and checklist.

Hmm, this is getting complex. Let me think about the cleanest approach:

**Option 1: Move then copy back**
- Move Mac/Ableton → T7
- Copy presets/MIDI from T7 → Mac
- Copy new stuff from NAS → Mac

**Option 2: Copy essentials, move rest**
- Copy essentials from Mac to temp location
- Move Mac/Ableton → T7
- Copy essentials from temp → Mac
- Copy new essentials from NAS → Mac

**Option 3: Keep structure**
- Keep Mac Ableton structure
- Just delete Sample Library from Mac (the big stuff)
- Add presets/MIDI to Mac structure from NAS
- This keeps Factory Packs on Mac though (28GB)

Actually, the user wants to maximize Mac space. So Factory Packs should go to T7 too.

I think the cleanest is:
1. Move entire Mac Ableton → T7
2. Copy back only small essentials from T7 → Mac
3. Copy new essentials from NAS → Mac

Let me update the checklist.
</thinking>

<function_calls>
<invoke name="TodoWrite">
<parameter name="todos">[{"content": "Scan all music production items on NAS with sizes", "activeForm": "Scanning all music production items on NAS with sizes", "status": "completed"}, {"content": "Categorize items by Ableton library structure", "activeForm": "Categorizing items by Ableton library structure", "status": "completed"}, {"content": "Create three-tier categorization (Mac/T7/NAS)", "activeForm": "Creating three-tier categorization (Mac/T7/NAS)", "status": "completed"}, {"content": "Create migration script for Mac essentials", "activeForm": "Creating migration script for Mac essentials", "status": "completed"}, {"content": "Create migration script for T7", "activeForm": "Creating migration script for T7", "status": "completed"}, {"content": "Generate Ableton Library.cfg update instructions", "activeForm": "Generating Ableton Library.cfg update instructions", "status": "completed"}, {"content": "Create cleanup checklist", "activeForm": "Creating cleanup checklist", "status": "in_progress"}]