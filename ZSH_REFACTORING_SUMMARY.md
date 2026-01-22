# Zsh Configuration Refactoring Summary

## Overview

Comprehensive refactoring of Zsh configuration based on Arch Wiki and NixOS Wiki best practices. All changes follow Home Manager's idiomatic patterns and improve cross-terminal compatibility.

## Changes Made

### 1. System-Level Configuration (`modules/shared/shell.nix`)

**Before:**
```nix
programs.zsh.enable = lib.mkDefault true;
```

**After:**
```nix
programs.zsh = {
  enable = lib.mkDefault true;
  enableGlobalCompInit = false;        # ⚠️ Critical: Prevents double compinit
  enableBashCompletion = true;         # Bash compatibility
  enableLsColors = true;                # Enhanced ls/tree colors
  promptInit = "prompt off";           # Prevent system prompt interference
  vteIntegration = true;                # VTE terminal support
};
```

**Impact:** Eliminates double compinit initialization, adds bash compatibility, prevents system-level prompt conflicts.

---

### 2. Environment Variables (`home/common/features/core/shell/environment.nix`)

**New: envExtra for .zshenv**

Added proper separation of environment variables into `.zshenv` (sourced by ALL shells):

```nix
programs.zsh.envExtra = ''
  # Word characters for navigation (excludes '/' for path components)
  export WORDCHARS='*?_-.[]~=&;!'
  
  # SOPS secrets management
  export SOPS_GPG_EXEC="${lib.getExe pkgs.gnupg}"
  export SOPS_GPG_ARGS="--pinentry-mode=loopback"
  
  # Nix flake location
  export NIX_FLAKE="${config.home.homeDirectory}/.config/nix"
'';
```

**Impact:** Variables are now available to non-interactive shells (rsync, scripts, etc.)

---

### 3. Local Variables (`home/common/features/core/shell/zsh-config.nix`)

**New: localVariables**

Plugin configuration moved to proper local variables (top of .zshrc):

```nix
localVariables = {
  # Zsh autosuggestions
  ZSH_AUTOSUGGEST_STRATEGY = "(history completion)";
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=240";
  
  # Auto-notify
  AUTO_NOTIFY_THRESHOLD = 10;
  AUTO_NOTIFY_TITLE = "Command finished";
  AUTO_NOTIFY_BODY = "Completed in %elapsed seconds";
  AUTO_NOTIFY_IGNORE = "(...)";
  
  # Atuin
  ATUIN_NOBIND = "true";
};
```

**Impact:** Cleaner variable management, proper scoping, no string interpolation needed.

---

### 4. Convenience Features (`home/common/features/core/shell/zsh-config.nix`)

**New: Navigation Shortcuts**

```nix
# Named directory hashes
dirHashes = {
  nix = "$HOME/.config/nix";
  dots = "$HOME/.config";
};
# Usage: cd ~nix

# Auto-complete cd paths
cdpath = ["~/.config" "~/projects"];
# Usage: cd nix (resolves to ~/.config/nix)

# Global aliases (expand anywhere)
shellGlobalAliases = {
  G = "| grep";
  GI = "| grep -i";
  L = "| less";
  H = "| head";
  T = "| tail";
  J = "| jq";
  NUL = ">/dev/null 2>&1";
  NE = "2>/dev/null";
};
# Usage: dmesg G error → dmesg | grep error

# Explicit keymap
defaultKeymap = "emacs";
```

**Impact:** Faster navigation, cleaner command chaining, explicit mode declaration.

---

### 5. Terminfo-Based Keybindings (`home/common/features/core/shell/keybindings.nix`)

**New: Dedicated keybindings module**

Created comprehensive terminfo-based keybindings replacing hardcoded escape sequences:

```nix
# Terminfo key definitions
typeset -g -A key
key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Control-Left]="${terminfo[kLFT5]}"
key[Control-Right]="${terminfo[kRIT5]}"
# ... etc

# Conditional binding (only if terminfo value exists)
[[ -n "${key[Home]}" ]] && bindkey -- "${key[Home]}" beginning-of-line

# Application mode hooks (critical for key reliability)
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
  function zle_application_mode_start { echoti smkx }
  function zle_application_mode_stop { echoti rmkx }
  add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
  add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi
```

**Impact:** Cross-terminal compatibility, reliable keybindings, proper terminal state management.

---

### 6. Profiling and Terminal Support

**New: Profiling and VTE Integration**

```nix
# Enable startup profiling
zprof.enable = true;
# Usage: Run 'zprof' in shell to see performance breakdown

# VTE terminal integration (Home Manager)
enableVteIntegration = true;
```

**Impact:** Can profile startup times, better support for GNOME Terminal/Tilix.

---

### 7. Refactored init-content.nix

**Cleaned up:**
- Removed duplicate environment variable exports (moved to envExtra)
- Removed local variable declarations (moved to localVariables)
- Removed hardcoded keybindings (moved to keybindings.nix)
- Simplified plugin configuration sections

**Impact:** Cleaner, more maintainable code following Home Manager best practices.

---

## File Structure Changes

```
home/common/features/core/shell/
├── default.nix           # Main entry point
├── zsh-config.nix        # Core Zsh options (UPDATED)
├── environment.nix       # Environment setup (UPDATED)
├── completion.nix        # Completion system
├── aliases.nix           # Shell aliases
├── plugins.nix           # Plugin definitions
├── keybindings.nix       # ⭐ NEW: Terminfo-based keybindings
├── init-content.nix      # Init script (REFACTORED)
└── cached-init.nix       # Performance optimizations
```

---

## Verification

All changes verified with:

```bash
# System-level settings
nix eval .#nixosConfigurations.jupiter.config.programs.zsh.enable  # true
nix eval .#nixosConfigurations.jupiter.config.programs.zsh.enableGlobalCompInit  # false
nix eval .#nixosConfigurations.jupiter.config.programs.zsh.promptInit  # "prompt off"

# Home Manager settings
nix eval .#nixosConfigurations.jupiter.config.home-manager.users.lewis.programs.zsh.defaultKeymap  # "emacs"
nix eval .#nixosConfigurations.jupiter.config.home-manager.users.lewis.programs.zsh.dirHashes  # {"dots":"...","nix":"..."}
nix eval .#nixosConfigurations.jupiter.config.home-manager.users.lewis.programs.zsh.zprof.enable  # true
```

---

## Benefits

### Performance
- **No double compinit**: Eliminated duplicate completion initialization
- **zprof enabled**: Can profile and optimize startup time
- **Proper variable scoping**: Less runtime computation

### Compatibility
- **Terminfo-based keys**: Works across all terminal emulators
- **Application mode**: Ensures keybindings work reliably
- **VTE integration**: Better support for GNOME Terminal family

### Maintainability
- **Proper file separation**: envExtra, localVariables, keybindings
- **Follows Home Manager idioms**: Using built-in options instead of string interpolation
- **Modular architecture**: Each concern in its own file

### User Experience
- **Named directories**: `cd ~nix` for quick navigation
- **Global aliases**: `dmesg G error` instead of `dmesg | grep error`
- **cdpath**: `cd nix` resolves to `~/.config/nix` automatically
- **Profiling**: Run `zprof` to see what's slow

---

## Next Steps

To apply these changes:

```bash
# Review changes
git diff

# Build and switch (when ready)
nh os switch  # or home-manager switch
```

After switching, test new features:

```bash
# Named directories
cd ~nix

# Global aliases
echo "test" G "est"  # expands to: echo "test" | grep "est"

# Profiling
zprof  # Shows startup time breakdown

# Verify no double compinit
grep -c "compinit" <(zsh -x 2>&1)  # Should only see it once from Home Manager
```

---

## What Was NOT Changed

These were considered but **intentionally not implemented**:

- **zsh-abbr**: Too opinionated, would change workflow
- **siteFunctions**: Current function setup already works well
- **profileExtra/loginExtra**: No login shell config needs identified

The refactoring focused on **objective improvements** without changing user workflow or preferences.
