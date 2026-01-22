# Zsh Optimization Changes

## Changes Made

### 1. Deferred Syntax Highlighting ✅

**File:** `home/common/features/core/shell/init-content.nix`

**Change:** Syntax highlighting now loads via `zsh-defer` instead of synchronously.

**Impact:** 
- Saves ~2.85ms on startup (13% of total init time)
- Still loads last among deferred plugins (maintains correct order)
- Prompt appears faster, highlighting loads in background

**Before:**
```nix
source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

**After:**
```nix
zsh-defer source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

### 2. Cleaned Up Old .zcompdump ✅

**Action:** Removed old completion dump at `~/.config/zsh/.zcompdump`

**Reason:** Config now correctly uses `~/.cache/zsh/.zcompdump` (XDG cache directory)

---

## Testing Results

### Instant Prompt Status
✅ **Working correctly** - Validation passed
- Cache file exists and is fresh
- Powerlevel10k loaded
- UTF-8 supported

### Profiling Results (Before Changes)
```
compinit:                   17.41ms (80.15%)  ← Expected, cached
_zsh_highlight_load:         2.85ms (13.13%)  ← NOW DEFERRED ✅
p10k:                        0.83ms (3.84%)
zsh-defer:                   0.26ms (1.21%)
```

**Expected improvement:** ~2.85ms faster startup (from ~21ms to ~18ms)

---

## Next Steps (User Testing Required)

### 1. Test YSU Hardcore Mode Impact

YSU hardcore mode wraps the `command` builtin and intercepts every command, causing ~14ms command lag.

**Test without hardcore mode:**
```zsh
# In current shell
unset YSU_HARDCORE
unfunction command 2>/dev/null
exec zsh  # Fresh shell
~/zsh-bench/zsh-bench  # Compare command_lag_ms
```

**If command lag improves significantly**, consider:
- Disabling hardcore mode: Remove `YSU_HARDCORE=1` from config
- Or removing YSU plugin entirely if you don't use it

### 2. Plugin Audit

Consider removing unused plugins to further reduce startup time:

**Candidates for removal:**
- `zsh-bd` - Quick directory navigation (do you use `bd` command?)
- `zsh-codex` - AI completion (do you use Ctrl+X?)
- `auto-notify` - Command finish notifications (are they useful?)
- `zsh-autopair` - Auto-closing brackets (do you need this?)

**To test impact:**
1. Comment out plugin in `init-content.nix`
2. Rebuild: `nh home switch`
3. Test startup: `zsh -ic 'zmodload zsh/zprof; source ~/.config/zsh/.zshrc; zprof' | head -20`

### 3. Further Optimization Opportunities

**If startup is still slow:**

1. **Pre-compile more scripts** (like zoxide/fzf/direnv):
   - Add plugin scripts to `powerlevel10k.nix` compilation step
   - Saves 5-15ms per script

2. **Aggressive completion caching:**
   - Current: Regenerates dump if >24 hours old
   - Could increase to 7 days if completions rarely change

3. **Remove unused completion sources:**
   - Check what's in `fpath` after init
   - Remove completion sources you don't use

---

## Rebuild Instructions

```bash
# 1. Rebuild home-manager
nh home switch

# 2. Start fresh shell (don't use source!)
exec zsh

# 3. Validate improvements
p10k-validate-instant
zsh -ic 'zmodload zsh/zprof; source ~/.config/zsh/.zshrc; zprof' | head -20

# 4. Compare startup time
time zsh -i -c 'exit'
```

---

## Expected Results

- **Startup time:** ~18ms (down from ~21ms)
- **Prompt appears:** Instantly (instant prompt working)
- **Command lag:** Still ~14ms if YSU hardcore mode enabled (test without it)

---

## Notes

- Syntax highlighting will load slightly after prompt appears (deferred)
- This is fine - highlighting activates when you start typing
- All functionality preserved, just faster startup
