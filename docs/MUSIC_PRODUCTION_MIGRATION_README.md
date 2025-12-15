# Music Production Library Migration Guide

## 🎯 Goal

Transform from **Mac-only library** to **three-tier professional workflow**:

1. **Mac Internal** (~2GB): Essential presets/MIDI (no errors when T7 unplugged)
2. **T7 SSD** (~46GB): Working library (portable, always with you)
3. **NAS** (~270GB): Deep archive (access when home via gigabit ethernet)

## 📊 Current State

- **Mac**: 43GB Ableton library (9GB free space - critical!)
- **T7**: 41GB old backup
- **NAS**: ~270GB music production content

## 📊 Final State

- **Mac**: 2.7GB essentials (52GB free - healthy!)
- **T7**: 46GB working library (886GB free for projects)
- **NAS**: 270GB archive (accessed when home)

---

## 🚀 Migration Steps

### Step 1: Move Mac → T7

```bash
./scripts/media/migrate-music-production-t7.sh --dry-run
./scripts/media/migrate-music-production-t7.sh
```

**This will:**
- Move entire `/Users/lewisflude/Music/Ableton/` → `/Volumes/Samsung Drive/Ableton/` (44GB)
- Copy XLNTSOUND Bass pack from NAS → T7 (1.5GB)
- Copy Analog Rytm samples from NAS → T7 (99MB)
- Copy video tutorials from NAS → T7 (458MB)
- Create Projects folder structure on T7

**Time:** 20-30 minutes

**Result:** Mac Ableton folder gone, T7 has everything

---

### Step 2: Copy Essentials to Mac

```bash
./scripts/media/migrate-music-production-mac.sh --dry-run
./scripts/media/migrate-music-production-mac.sh
```

**This will copy FROM NAS → Mac:**
- FabFilter presets (4MB)
- KICK 3 presets (329MB)
- Serum presets (77MB)
- JUP-8000 presets (12MB)
- Ableton Racks (242KB)
- MIDI packs (38MB)
- Plugin installers (1.95GB)
- Reference books (610KB)

**THEN manually copy FROM T7 → Mac:**
```bash
# DX7 banks (already on T7 after Step 1)
mkdir -p ~/Music/Ableton/User\ Library/Presets/Instruments/DX7/
cp -R "/Volumes/Samsung Drive/Ableton/User Library/Sample Library/Matt.Curry.DX7"* \
  ~/Music/Ableton/User\ Library/Presets/Instruments/DX7/

# TX81Z Max4Live device
mkdir -p ~/Music/Ableton/User\ Library/Presets/MIDI\ Effects/Max\ MIDI\ Effect/
cp -R "/Volumes/Samsung Drive/Ableton/User Library/Sample Library/midierror.Yamaha.TX81Z.Editor.[Max4Live]" \
  ~/Music/Ableton/User\ Library/Presets/MIDI\ Effects/Max\ MIDI\ Effect/
```

**Time:** 15-20 minutes

**Result:** Mac has ~2.7GB of essentials, T7 still has full library

---

### Step 3: Update Ableton Configuration

```bash
./scripts/media/update-ableton-library-paths.sh --dry-run
./scripts/media/update-ableton-library-paths.sh
```

**This will:**
- Update `Library.cfg` to point to T7 as primary library
- Backup old config
- Provide instructions for adding NAS as secondary path

**Then in Ableton:**
1. Launch Ableton Live
2. Go to `Preferences → Library → Folders to Index`
3. Click "+ Add Folder" and add:
   - `/Volumes/storage/torrents/music-production`
   - `/Volumes/storage/torrents`

**Time:** 5 minutes

**Result:** Ableton configured for three-tier workflow

---

### Step 4: Verify Everything Works

#### Test 1: With T7 Connected
- [ ] Open Ableton
- [ ] Browser shows all content (Factory Packs, User Library, NAS)
- [ ] Load a preset from Mac (FabFilter, KICK)
- [ ] Load a sample from T7 (jungle pack)
- [ ] Load a sample from NAS (Analog Rytm)
- [ ] Create and save a project to T7: `/Volumes/Samsung Drive/Projects/Active/`

#### Test 2: WITHOUT T7 (Critical!)
- [ ] Eject T7
- [ ] Restart Ableton
- [ ] FabFilter presets load ✓ (from Mac)
- [ ] KICK presets load ✓ (from Mac)
- [ ] Serum presets load ✓ (from Mac)
- [ ] MIDI clips load ✓ (from Mac)
- [ ] DX7 banks load ✓ (from Mac)
- [ ] T7 samples show "missing" (expected, not an error)

#### Test 3: With T7 Reconnected
- [ ] Plug in T7
- [ ] Restart Ableton
- [ ] All "missing" samples now available ✓

---

## ✅ Verification Checklist

After migration, verify these sizes:

### Mac Internal SSD
```bash
df -h /
# Should show ~52GB free (was 9GB)

du -sh ~/Music/Ableton/User\ Library/
# Should show ~700MB (presets/MIDI only)

du -sh ~/Music/Plugin\ Installers/
# Should show ~2GB
```

### T7 Samsung Drive
```bash
du -sh "/Volumes/Samsung Drive/Ableton"
# Should show ~46GB

ls "/Volumes/Samsung Drive/Projects"
# Should show: Active/ Archive/ Samples/
```

### NAS (unchanged)
```bash
ls -lh /Volumes/storage/torrents/music-production/
# All original content still there ✓
```

---

## 🎹 Workflow After Migration

### Making Music Portable (T7 plugged in)
- Full access to 46GB working library
- 886GB free for new projects
- Fast SSD performance
- Save projects to `/Volumes/Samsung Drive/Projects/Active/`

### Making Music Without T7
- All presets/MIDI still work (from Mac)
- Can sketch ideas, write MIDI
- Can use "Collect All and Save" to make project portable
- Missing samples show as "missing" but don't break Ableton

### Making Music at Home (NAS + T7)
- Full library access (T7 + NAS)
- Superior Drummer available
- Samples From Mars available
- Fast gigabit ethernet performance

---

##Files and Sizes Reference

### What's on Mac (~2.7GB)

| Item | Size | Location |
|------|------|----------|
| FabFilter Presets | 4.1MB | `~/Music/Ableton/User Library/Presets/Audio Effects/FabFilter/` |
| KICK 3 Presets | 329MB | `~/Music/Ableton/User Library/Presets/Instruments/KICK-3/` |
| Serum Presets | 77MB | `~/Music/Ableton/User Library/Presets/Instruments/Serum/` |
| JUP-8000 Presets | 12MB | `~/Music/Ableton/User Library/Presets/Instruments/JUP-8000/` |
| DX7 Banks | 283MB | `~/Music/Ableton/User Library/Presets/Instruments/DX7/` |
| Ableton Racks | 242KB | `~/Music/Ableton/User Library/Presets/Audio Effects/Ableton/` |
| MIDI Packs | 38MB | `~/Music/Ableton/User Library/Clips/MIDI/` |
| TX81Z Max4Live | 331KB | `~/Music/Ableton/User Library/Presets/MIDI Effects/` |
| Plugin Installers | 1.95GB | `~/Music/Plugin Installers/macOS/` |
| Reference Books | 610KB | `~/Documents/Music Production/Books/` |
| **TOTAL** | **~2.7GB** | |

### What's on T7 (~46GB)

| Item | Size | Location |
|------|------|----------|
| Factory Packs | 28GB | `/Volumes/Samsung Drive/Ableton/Factory Packs/` |
| Jungle/DnB Samples | 7.5GB | `/Volumes/Samsung Drive/Ableton/User Library/Sample Library/` |
| TX81Z Kontakt | 5.3GB | `/Volumes/Samsung Drive/Ableton/User Library/Sample Library/` |
| DX7 Banks | 283MB | `/Volumes/Samsung Drive/Ableton/User Library/Sample Library/` |
| XLNTSOUND Bass Pack | 1.5GB | `/Volumes/Samsung Drive/Ableton/User Library/Sample Library/Bass/` |
| Analog Rytm Samples | 119MB | `/Volumes/Samsung Drive/Ableton/User Library/Sample Library/Analog-Rytm/` |
| Video Tutorials | 458MB | `/Volumes/Samsung Drive/Ableton/User Library/Tutorials/` |
| Other Samples | ~2GB | `/Volumes/Samsung Drive/Ableton/User Library/` |
| **TOTAL** | **~46GB** | |
| **Projects (free)** | **886GB** | `/Volumes/Samsung Drive/Projects/` |

### What's on NAS (~270GB)

| Item | Size | Location |
|------|------|----------|
| Superior Drummer 3 | 208GB | `/Volumes/storage/torrents/` (multiple parts) |
| Samples From Mars | 59GB | `/Volumes/storage/torrents/music-production/samples/` |
| Plugin Installers | 1.95GB | `/Volumes/storage/torrents/music-production/macos/` |
| Other Content | ~1GB | `/Volumes/storage/torrents/music-production/` |
| **TOTAL** | **~270GB** | |

---

## 🔧 Troubleshooting

### "NAS not mounted"
```bash
# Check if NAS is available
ping jupiter

# Mount manually if needed
open smb://jupiter/storage
```

### "T7 not found"
```bash
# Check if T7 is connected
diskutil list | grep Samsung

# Should show /dev/disk7s1 mounted at "/Volumes/Samsung Drive"
```

### "Permission denied" copying files
```bash
# Fix T7 permissions (if needed)
sudo chown -R $(whoami) "/Volumes/Samsung Drive"
```

### Ableton shows "Can't find file"
- Check if T7 is plugged in
- Check if NAS is mounted
- Check Library paths in Preferences → Library

### Want to remove TX81Z Kontakt from T7 to save space?
```bash
# It's 5.3GB - if you have the Max4Live editor, you might not need it
rm -rf "/Volumes/Samsung Drive/Ableton/User Library/Sample Library/norCTrack.Yamaha.TX81Z.NKI.KONTAKT"

# This frees 5.3GB on T7
```

---

## 📝 Scripts Summary

All scripts support `--dry-run` for testing:

1. **migrate-music-production-t7.sh**
   - Moves Mac Ableton → T7
   - Copies new NAS content → T7
   - Run this FIRST

2. **migrate-music-production-mac.sh**
   - Copies essentials from NAS → Mac
   - Run this SECOND
   - Then manually copy DX7/TX81Z from T7 → Mac

3. **update-ableton-library-paths.sh**
   - Updates Ableton config to point to T7
   - Run this THIRD

---

## 🎉 Benefits After Migration

✅ **Mac freed**: 43GB → 52GB free (safe operating space)
✅ **Portable**: T7 in bag = full production setup anywhere
✅ **No errors**: Presets/MIDI always work without T7
✅ **Fast access**: SSD speeds (T7) + gigabit ethernet (NAS)
✅ **Organized**: Three-tier system matches workflow needs
✅ **Scalable**: 886GB free on T7 for growth
✅ **Backed up**: NAS keeps original torrents (still seeding)

---

## ⚠️ Important Notes

1. **NAS files are COPIED, not moved** - originals stay on NAS (torrents keep seeding)
2. **Mac Ableton folder is MOVED** - it goes to T7, then essentials copied back
3. **Always test with --dry-run first!**
4. **Don't delete Mac Ableton manually** - let the T7 script move it
5. **Verify Step 4 before celebrating** - make sure T7 library works!

---

## 📞 Need Help?

Check:
- This README
- Migration checklist: `MUSIC_PRODUCTION_MIGRATION_CHECKLIST.md`
- Script source: `scripts/media/migrate-music-production-*.sh`
