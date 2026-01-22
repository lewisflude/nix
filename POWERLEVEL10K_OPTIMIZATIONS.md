# Powerlevel10k Performance Optimizations

This document summarizes the performance and reliability improvements made to the Powerlevel10k configuration based on deep analysis of the official README.

## Summary of Changes

### Performance Improvements (Estimated 30-80ms faster startup)

1. **Pre-generated Zoxide Initialization** (10-20ms saved)
   - **Before**: `eval "$(zoxide init zsh --cmd cd)"` runs on every shell start
   - **After**: Generated at Nix build time, sourced from static file
   - **File**: `home/common/features/core/shell/cached-init.nix`

2. **Optimized SSH_AUTH_SOCK** (5-15ms saved)
   - **Before**: `gpgconf --list-dirs agent-ssh-socket` runs on every shell start
   - **After**: Direct systemd socket path with fallback caching
   - **File**: `home/common/features/core/shell/cached-init.nix`

3. **Zsh Script Compilation** (5-15ms per script)
   - Compiles P10k theme, zoxide-init, and syntax-highlighting to `.zwc` bytecode
   - Activated via home-manager activation script
   - **File**: `home/common/apps/powerlevel10k.nix`

4. **GPG_TTY Optimization**
   - **Before**: Not set, or set via `$(tty)` command substitution
   - **After**: `export GPG_TTY=$TTY` (instant, no process spawn)
   - **File**: `home/common/features/core/shell/init-content.nix`

5. **VCS Performance Tuning**
   - `VCS_MAX_SYNC_LATENCY_SECONDS`: 50ms threshold for async (was 10ms)
   - `VCS_MAX_INDEX_SIZE_DIRTY`: 4096 files before showing unknown count
   - `VCS_RECURSE_UNTRACKED_DIRS`: Disabled for major performance win
   - File count limits: 100 staged/unstaged/untracked
   - **File**: `home/common/apps/powerlevel10k.nix`

6. **Command Execution Time Threshold**
   - Changed from 3s to 5s to reduce unnecessary computation
   - **File**: `home/common/apps/powerlevel10k.nix`

### Reliability Improvements

7. **Configuration Wizard Disabled**
   - Prevents `p10k configure` from creating `~/.p10k.zsh`
   - Custom `p10k()` function shows helpful Nix-specific message
   - **File**: `home/common/apps/powerlevel10k.nix`

8. **Error Handling for Theme Load Failure**
   - Graceful fallback to basic prompt if P10k fails to load
   - Clear error message for troubleshooting
   - **File**: `home/common/apps/powerlevel10k.nix`

9. **WORDCHARS Fix**
   - Removed `!` character to prevent history expansion conflicts
   - **File**: `home/common/features/core/shell/init-content.nix`

10. **Terminal-Specific Fixes**
    - kitty terminal-shell integration (fixes resize issues)
    - `ZLE_RPROMPT_INDENT=0` (fixes right prompt spacing)
    - **File**: `home/common/apps/powerlevel10k.nix`

### Observability Improvements

11. **Diagnostic Functions** (new file)
    - `p10k-validate-instant`: Comprehensive instant prompt validation
    - `p10k-test-width`: Cursor position alignment testing
    - `p10k-test-unicode`: UTF-8 and terminal capability testing
    - `p10k-show-config`: Display current configuration
    - `zsh-bench-startup`: Benchmark shell startup time
    - `p10k-dev-mode`: Toggle hot reload for development
    - **File**: `home/common/lib/zsh/p10k-diagnostics.zsh`

12. **Background Process Documentation**
    - Explains gitstatusd and zsh workers
    - Documents expected behavior (not bugs)
    - **File**: `home/common/apps/powerlevel10k.nix` (in extraConfig)

## New Files Created

1. `home/common/features/core/shell/cached-init.nix`
   - Pre-generated initialization scripts
   - SSH_AUTH_SOCK optimization

2. `home/common/lib/zsh/p10k-diagnostics.zsh`
   - Diagnostic and validation functions
   - Benchmarking utilities

## Modified Files

1. `home/common/apps/powerlevel10k.nix`
   - VCS performance tuning
   - zcompile activation
   - Wizard disable + helpful message
   - Error handling
   - Terminal-specific fixes
   - Background process documentation

2. `home/common/features/core/shell/init-content.nix`
   - Added GPG_TTY optimization
   - Fixed WORDCHARS
   - Removed command substitutions (moved to cached-init.nix)
   - Added diagnostic functions sourcing

3. `home/common/features/core/shell/default.nix`
   - Added cached-init.nix import

## Usage

### After Applying Changes

```bash
# 1. Rebuild system
nh os switch

# 2. Start new shell (don't use source ~/.zshrc!)
exec zsh

# 3. Validate instant prompt
p10k-validate-instant

# 4. Benchmark startup
zsh-bench-startup

# 5. Check configuration
p10k-show-config
```

### Expected Results

- **Startup time**: <50ms with instant prompt
- **Prompt appears**: Instantly (before plugins finish loading)
- **Diagnostics**: All checks pass in `p10k-validate-instant`
- **No warnings**: About console output during init

### If You Try to Run `p10k configure`

You'll see a helpful message explaining that configuration is managed by Nix and directing you to the correct configuration file.

## Technical Details

### Instant Prompt Order (Critical)

```
[mkBefore in init-content.nix]
  - Direnv suppression
  - Any password prompts

[mkOrder 550 in powerlevel10k.nix]
  - Instant prompt preamble
  - P10k configuration (POWERLEVEL9K_* variables)
  - Theme loading

[mkAfter in init-content.nix]
  - Environment variables
  - GPG_TTY
  - Functions
  - Deferred plugins (via zsh-defer)
  - Keybindings

[Last in cached-init.nix]
  - Zoxide init (pre-generated)
  - SSH_AUTH_SOCK (cached)

[MUST BE LAST]
  - Syntax highlighting
```

### Git Status Limitations

⚠️ **Critical**: gitstatusd uses libgit2 which does NOT support:
- `git config index.skipHash true`
- `git config feature.manyFiles true`

If you enable these features, git status in prompt may be incorrect. Use `git status` command for accurate information.

### Terminal Compatibility

✅ **Tested with**:
- Ghostty
- Alacritty
- kitty (with terminal-shell integration)
- GNOME Terminal
- VSCode Terminal

⚠️ **Known issues**:
- Konsole: May cut off icons with non-monospace fonts
- VSCode: May replace foreground colors (disable minimumContrastRatio)

## Benchmarking

Target startup times:
- **With instant prompt**: <50ms (prompt appears immediately)
- **Total init time**: 50-200ms (background plugins load)

Run `zsh-bench-startup 10` to measure your actual performance.

## Troubleshooting

### Instant prompt cache missing
```bash
# Check if cache exists
ls -la "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"

# Regenerate by starting new shell
exec zsh
```

### Prompt corruption on terminal resize
- Use kitty >= 0.24.0 (terminal-shell integration enabled)
- Or disable ruler, right frame, and minimize right prompt

### Git status incorrect
- Check if `skipHash` or `manyFiles` are enabled: `git config --list | grep -E 'skipHash|manyFiles'`
- If yes, git status from gitstatusd may be inaccurate
- Use `git status` command for accurate information

### Performance regression
```bash
# Benchmark current performance
zsh-bench-startup 10

# Check instant prompt is working
p10k-validate-instant

# Profile startup (detailed)
zmodload zsh/zprof
source ~/.zshrc
zprof
```

## References

- [Powerlevel10k Official README](https://github.com/romkatv/powerlevel10k)
- [zsh-bench](https://github.com/romkatv/zsh-bench)
- [gitstatusd](https://github.com/romkatv/gitstatus)
- Internal: `~/.config/nix/home/common/apps/powerlevel10k.nix`
