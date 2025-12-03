# Newline Keybinding Guide

This document provides comprehensive guidance on configuring `Shift+Enter` to insert newlines across different applications on macOS and NixOS.

## The Problem

By default, pressing `Enter` in many applications (especially chat apps, terminal prompts, and code editors) triggers a submit/send action. To insert a newline without triggering this action, you typically need to use a modifier key with `Enter`.

## Standard Keybindings by Platform

### macOS

| Keybinding | Purpose | Common Usage |
|------------|---------|--------------|
| `Shift + Enter` | Insert newline | Most apps (preferred) |
| `Option + Enter` | Insert newline | Alternative in some apps |
| `Cmd + Enter` | Submit/Send | Many chat apps |
| `Ctrl + Enter` | Insert newline | Some terminal apps |

### Linux/NixOS

| Keybinding | Purpose | Common Usage |
|------------|---------|--------------|
| `Shift + Enter` | Insert newline | Most apps (preferred) |
| `Ctrl + Enter` | Submit/Send | Many apps |
| `Alt + Enter` | Insert newline | Alternative in some apps |

## Configuration by Application

### 1. Ghostty Terminal

**Configuration Location:** `~/.config/ghostty/config`

**Nix Configuration:** `home/common/features/core/terminal.nix`

```nix
programs.ghostty = {
  enable = true;
  settings = {
    # IMPORTANT: Use double single quotes to preserve the literal \n
    keybind = [ ''shift+enter=text:\n'' ];
  };
};
```

**Manual Configuration:**

```conf
# In ~/.config/ghostty/config
keybind = shift+enter=text:\n
```

**Testing:**
1. Open Ghostty
2. Type: `echo "line 1"`
3. Press `Shift+Enter`
4. Type: `echo "line 2"`
5. Press `Enter` to execute
6. Both commands should execute on separate lines

### 2. ZSH Shell (in Ghostty)

**Configuration Location:** Managed by `home/common/features/core/shell.nix`

**How it Works:**
- Ghostty sends escape sequences when `Shift+Enter` is pressed
- ZSH intercepts these sequences and inserts a newline into the command buffer
- Works for both emacs and vi modes

**The Configuration:**

```nix
# In home/common/features/core/shell.nix
programs.zsh = {
  initExtra = ''
    # Ghostty multiline input support
    function _ghostty_insert_newline() { LBUFFER+=$'\n' }
    zle -N ghostty-insert-newline _ghostty_insert_newline
    bindkey -M emacs $'\e[99997u' ghostty-insert-newline
    bindkey -M viins $'\e[99997u' ghostty-insert-newline
    bindkey -M emacs $'\e\r'     ghostty-insert-newline
    bindkey -M viins $'\e\r'     ghostty-insert-newline
  '';
};
```

**Testing:**
1. Open Ghostty
2. Type a partial command: `for i in 1 2 3; do`
3. Press `Shift+Enter` (cursor should move to next line)
4. Type: `  echo $i`
5. Press `Shift+Enter`
6. Type: `done`
7. Press `Enter` to execute the multi-line loop

### 3. Cursor Editor

**Problem:** Cursor might use `Shift+Enter` for AI suggestions or other features.

**Solution:** Add custom keybinding

**Location:** 
- macOS: `~/Library/Application Support/Cursor/User/keybindings.json`
- Linux: `~/.config/Cursor/User/keybindings.json`

**Configuration:**

```json
[
  {
    "key": "shift+enter",
    "command": "editor.action.insertLineAfter",
    "when": "editorTextFocus && !editorReadonly && !suggestWidgetVisible"
  },
  {
    "key": "shift+enter",
    "command": "editor.action.insertLineBreak",
    "when": "textInputFocus && !editorReadonly"
  }
]
```

**Alternative Keybindings for Cursor:**
- `Cmd+Enter` (macOS) / `Ctrl+Enter` (Linux): Accept AI suggestion
- `Option+Enter` (macOS) / `Alt+Enter` (Linux): Quick fix / code actions

**Testing:**
1. Open any file in Cursor
2. Position cursor at end of a line
3. Press `Shift+Enter`
4. New line should be inserted

### 4. Claude Desktop App

**Built-in Behavior:**
- `Enter` → Sends message
- `Shift+Enter` → Inserts newline (built-in, should work by default)

**If Not Working:**

**Possible Causes:**
1. **Keyboard remapping software** (Karabiner Elements, BetterTouchTool)
2. **System keyboard shortcuts** conflicting
3. **App-specific bugs** (try restarting the app)

**Workarounds:**
1. Try `Option+Enter` (macOS) or `Alt+Enter` (Linux)
2. Compose in a text editor, then paste
3. Use the web version instead (claude.ai)

**Testing:**
1. Open Claude desktop app
2. In the message input field, type "Line 1"
3. Press `Shift+Enter`
4. Type "Line 2"
5. Both lines should be visible before sending

### 5. Gemini CLI

**Configuration Location:** `home/common/apps/gemini-cli.nix`

**Built-in Behavior:**
- Uses standard terminal input
- `Shift+Enter` behavior depends on your terminal (Ghostty)
- Should work automatically if Ghostty is configured correctly

**Alternative:** Multi-line input mode
```bash
# In gemini-cli, you can paste multi-line input directly
# Or use a heredoc:
gemini-cli << 'EOF'
This is line 1
This is line 2
This is line 3
EOF
```

### 6. Web Browsers (Claude, Gemini, ChatGPT web interfaces)

**Standard Behavior:**
- Most modern web chat interfaces support `Shift+Enter` for newlines
- This is implemented in JavaScript, not your terminal config

**If Not Working:**

1. **Check browser extensions**
   - Some keyboard shortcut extensions can interfere
   - Test in incognito/private mode

2. **Check browser shortcuts**
   - Chrome/Arc: `chrome://settings/searchEngines`
   - Safari: System Settings > Keyboard > Shortcuts

3. **Browser-specific issues**
   - **Arc Browser:** Known to have custom keyboard handling
   - **Brave:** Check "Shields" settings
   - **Firefox:** Check about:config for keyboard settings

**Workarounds:**
- `Option+Enter` (macOS) / `Alt+Enter` (Linux)
- Compose in a text editor, then paste
- Use markdown syntax for line breaks (two spaces + Enter)

### 7. VSCode (if you use it alongside Cursor)

**Same as Cursor** - uses `keybindings.json`

**Quick Settings:**
1. Press `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Linux)
2. Type "Preferences: Open Keyboard Shortcuts (JSON)"
3. Add the same configuration as Cursor above

## Debugging Workflow

When `Shift+Enter` doesn't work, follow this diagnostic process:

### Step 1: Verify Baseline Functionality

**Test in a simple app:**
- macOS: TextEdit, Notes
- Linux: gedit, Kate

If it works there, the issue is application-specific.

### Step 2: Check System-Level Conflicts

#### macOS:
```bash
# Check for keyboard shortcut conflicts
# System Settings > Keyboard > Keyboard Shortcuts
# Look for shortcuts using Enter/Return

# Check if Karabiner is intercepting
pgrep karabiner && echo "Karabiner is running"

# Temporarily disable Karabiner
osascript -e 'quit app "Karabiner-Elements"'

# Re-enable Karabiner
open -a "Karabiner-Elements"
```

#### Linux (NixOS):
```bash
# Check for compositor/window manager shortcuts
# GNOME
gsettings list-recursively org.gnome.desktop.wm.keybindings | grep -i return

# KDE
kwriteconfig5 --file ~/.config/kglobalshortcutsrc --list

# Check input method conflicts
echo $GTK_IM_MODULE
echo $QT_IM_MODULE
```

### Step 3: Application-Specific Testing

**Create a test file:**
```bash
cat > /tmp/newline-test.txt << 'EOF'
Line 1 [Press Shift+Enter here]
Line 2 [Press Shift+Enter here]
Line 3 [Press Enter here to finish]
EOF
```

Open this file in each application and test.

### Step 4: Check Configuration Files

```bash
# Ghostty config
cat ~/.config/ghostty/config | grep keybind

# Should show: keybind = shift+enter=text:\n

# If missing \n, the config is broken
# Rebuild home-manager configuration
```

### Step 5: Rebuild Configuration

#### NixOS:
```bash
# Rebuild home-manager
home-manager switch

# Or use nh (if available)
nh home switch
```

#### macOS (nix-darwin):
```bash
# Rebuild darwin configuration
# Note: Run this manually, don't use automated tools
darwin-rebuild switch --flake ~/.config/nix
```

## Common Issues and Solutions

### Issue 1: Ghostty `\n` Disappearing

**Problem:** The `\n` in `keybind = shift+enter=text:\n` is being interpreted as a newline by Nix.

**Solution:** Use Nix's `''` (two single quotes) for literal strings:

```nix
# Wrong (string interpolation)
keybind = [ "shift+enter=text:\n" ];

# Correct (literal string)
keybind = [ ''shift+enter=text:\n'' ];
```

### Issue 2: Karabiner Elements Interference

**Problem:** Karabiner is remapping keys and interfering with Shift+Enter.

**Solution:**
1. Check `~/.config/karabiner/karabiner.json` for rules involving `return_or_enter`
2. Add device-specific conditions to avoid conflicts
3. Temporarily disable Karabiner to test

### Issue 3: App Doesn't Respond to Shift+Enter

**Problem:** Some apps hardcode their keybindings.

**Solution:** Use app-specific alternatives:
- Claude Desktop: Use web version
- Cursor: Add custom keybinding (see Cursor section)
- Terminal: Ensure Ghostty + ZSH config is correct

### Issue 4: Works in Terminal but Not in Apps

**Problem:** Terminal config doesn't affect GUI applications.

**Solution:** Each GUI app needs its own configuration:
- Cursor/VSCode: `keybindings.json`
- Web apps: Browser-dependent, usually works by default
- Native apps: App-dependent, check app preferences

## Alternative Keybindings

If `Shift+Enter` continues to be problematic, consider these alternatives:

### macOS:
1. `Option+Enter` - Less commonly used, fewer conflicts
2. `Cmd+Shift+Enter` - More complex, but unique
3. `Control+Enter` - Unix-style alternative

### Linux:
1. `Alt+Enter` - Common alternative
2. `Ctrl+Shift+Enter` - More complex binding
3. `Ctrl+J` - Traditional Unix newline character

## Testing Your Configuration

Run the debugging script:

```bash
# From your nix config directory
./scripts/debug-newline-keybinding.sh
```

This will:
1. Check Ghostty configuration
2. Verify ZSH setup
3. Look for conflicts (Karabiner, system shortcuts)
4. Check app-specific configurations
5. Provide a test file and troubleshooting steps

## Per-Application Configuration Matrix

| Application | Config Method | Config Location | Status |
|-------------|---------------|-----------------|--------|
| **Ghostty** | Nix + config file | `~/.config/ghostty/config` | ✅ Configured |
| **ZSH** | Nix (home-manager) | Managed by shell.nix | ✅ Configured |
| **Cursor** | JSON keybindings | `~/Library/Application Support/Cursor/User/keybindings.json` | ⚠️ Manual setup needed |
| **Claude Desktop** | Built-in | N/A (app-controlled) | ✅ Should work by default |
| **Gemini CLI** | Terminal-based | Uses Ghostty config | ✅ Works via terminal |
| **Web Apps** | Browser | N/A (JavaScript) | ✅ Should work by default |
| **VSCode** | JSON keybindings | Same as Cursor | ⚠️ Manual setup needed |

## Recommended Configuration

For the best cross-application experience:

1. **Use `Shift+Enter` as primary** - Most widely supported
2. **Configure fallback to `Option+Enter`** (macOS) or `Alt+Enter` (Linux)
3. **Keep `Cmd+Enter` for submit/send actions** (macOS convention)
4. **Document app-specific quirks** in this file

## Resources

- **Ghostty Documentation**: https://ghostty.org/docs/config/reference
- **Karabiner Elements**: https://karabiner-elements.pqrs.org/
- **VSCode Keybindings**: https://code.visualstudio.com/docs/getstarted/keybindings
- **Nix String Syntax**: https://nix.dev/manual/nix/latest/language/values#string

## Contributing

If you find additional application-specific solutions or workarounds, please document them here following the existing format.
