# Zellij Configuration Reference

Technical reference for Zellij configuration in this Nix setup.

## 📋 Table of Contents

- [Configuration Files](#configuration-files)
- [Settings](#settings)
- [Keybindings](#keybindings)
- [Layouts](#layouts)
- [Shell Integration](#shell-integration)
- [Direnv Integration](#direnv-integration)
- [Customization](#customization)

---

## Configuration Files

### Primary Configuration

```
home/common/apps/zellij.nix          # Main Nix module
home/common/apps/zellij-config.kdl   # Keybindings (KDL format)
home/common/shell.nix                # Shell integration
home/common/lib/zsh/functions.zsh    # Helper functions
```

### Generated Files

After Home Manager builds, Zellij configuration is symlinked to:

```
~/.config/zellij/config.kdl          # Combined configuration
~/.config/zellij/layouts/            # Layout files
~/.config/direnv/lib/layout_zellij.sh # Direnv integration
```

---

## Settings

### Core Settings

```nix
# home/common/apps/zellij.nix
programs.zellij = {
  enable = true;
  package = pkgs.zellij;
  enableZshIntegration = true;

  settings = lib.mkForce {
    # Appearance
    theme = "default";
    pane_frames = true;
    simplified_ui = false;  # Show session info
    
    # Behavior
    default_mode = "locked";  # Don't interfere with terminal apps
    mouse_mode = true;
    copy_on_select = true;
    
    # Performance
    scroll_buffer_size = 100000;
    scroll_rebuffer_on_resize = true;
    
    # Session Management
    session_serialization = true;  # Save session state
    on_force_close = "quit";       # Clean exit
  };
};
```

### Setting Descriptions

| Setting | Type | Description |
|---------|------|-------------|
| `theme` | string | Color theme name |
| `default_mode` | string | Starting mode: "normal" or "locked" |
| `mouse_mode` | boolean | Enable mouse support |
| `scroll_buffer_size` | integer | Lines of scrollback (default: 10000) |
| `pane_frames` | boolean | Show frames around panes |
| `copy_on_select` | boolean | Auto-copy on text selection |
| `session_serialization` | boolean | Save/restore session layout |
| `on_force_close` | string | Behavior on force close: "quit" or "detach" |
| `simplified_ui` | boolean | Minimal UI mode |
| `scroll_rebuffer_on_resize` | boolean | Reflow text on terminal resize |

---

## Keybindings

### Configuration Format

Keybindings are defined in KDL (KDL Document Language):

```kdl
// home/common/apps/zellij-config.kdl
keybinds {
  normal {
    bind "Alt h" { MoveFocus "Left"; }
    bind "Alt j" { MoveFocus "Down"; }
    // ...
  }
  locked {
    bind "Ctrl g" { SwitchToMode "normal"; }
  }
}
```

### Modes

| Mode | Purpose | How to Enter |
|------|---------|--------------|
| `normal` | Normal operation with keybindings active | `Ctrl+g` from locked |
| `locked` | Locked mode - most keys pass through | Default mode |
| `scroll` | Scrollback navigation and search | `Alt+/` |
| `session` | Session management | `Alt+o` |
| `renametab` | Rename current tab | `Alt+r` |
| `entersearch` | Search in scrollback | `/` in scroll mode |

### Complete Keybinding Table

#### Normal Mode

**Navigation:**
| Binding | Action | Notes |
|---------|--------|-------|
| `Alt+h` | MoveFocus "Left" | Vim-style |
| `Alt+j` | MoveFocus "Down" | Vim-style |
| `Alt+k` | MoveFocus "Up" | Vim-style |
| `Alt+l` | MoveFocus "Right" | Vim-style |

**Pane Management:**
| Binding | Action | Notes |
|---------|--------|-------|
| `Alt+d` | NewPane "Right" | Split vertically |
| `Alt+s` | NewPane "Down" | Split horizontally |
| `Alt+n` | NewPane | Floating pane |
| `Alt+w` | CloseFocus | Close current pane |
| `Alt+f` | ToggleFocusFullscreen | Maximize pane |

**Pane Resizing:**
| Binding | Action | Notes |
|---------|--------|-------|
| `Alt+H` | Resize "Increase Left" | Shift+h |
| `Alt+J` | Resize "Increase Down" | Shift+j |
| `Alt+K` | Resize "Increase Up" | Shift+k |
| `Alt+L` | Resize "Increase Right" | Shift+l |

**Tab Management:**
| Binding | Action | Notes |
|---------|--------|-------|
| `Alt+t` | NewTab | Create new tab |
| `Alt+1` | GoToTab 1 | Jump to tab 1 |
| `Alt+2` | GoToTab 2 | Jump to tab 2 |
| `Alt+3` | GoToTab 3 | Jump to tab 3 |
| `Alt+4` | GoToTab 4 | Jump to tab 4 |
| `Alt+5` | GoToTab 5 | Jump to tab 5 |
| `Alt+6` | GoToTab 6 | Jump to tab 6 |
| `Alt+7` | GoToTab 7 | Jump to tab 7 |
| `Alt+8` | GoToTab 8 | Jump to tab 8 |
| `Alt+9` | GoToTab 9 | Jump to tab 9 |
| `Alt+[` | GoToPreviousTab | Previous tab |
| `Alt+]` | GoToNextTab | Next tab |
| `Alt+r` | SwitchToMode "renametab" | Rename tab |

**Session & Modes:**
| Binding | Action | Notes |
|---------|--------|-------|
| `Alt+o` | SwitchToMode "session" | Session management |
| `Alt+q` | Quit | Quit Zellij |
| `Alt+/` | SwitchToMode "scroll" | Enter scroll mode |

#### Locked Mode

| Binding | Action | Notes |
|---------|--------|-------|
| `Ctrl+g` | SwitchToMode "normal" | Unlock |

#### Scroll Mode

| Binding | Action | Notes |
|---------|--------|-------|
| `j` / `Down` | ScrollDown | One line down |
| `k` / `Up` | ScrollUp | One line up |
| `d` | HalfPageScrollDown | Half page down |
| `u` | HalfPageScrollUp | Half page up |
| `g` | ScrollToTop | Jump to top |
| `G` | ScrollToBottom | Jump to bottom |
| `/` | SwitchToMode "entersearch" | Search mode |
| `Esc` | SwitchToMode "normal" | Exit scroll |

### Customizing Keybindings

To add or modify keybindings, edit `home/common/apps/zellij-config.kdl`:

```kdl
keybinds {
  normal {
    // Add custom binding
    bind "Alt x" { NewPane "Right"; CloseFocus; }
    
    // Override existing binding
    bind "Alt t" { NewTab; SwitchToMode "renametab"; }
  }
}
```

Then rebuild: `switch`

---

## Layouts

### Default Layout

```nix
# home/common/apps/zellij.nix
layouts.default = ''
  layout {
    pane focus=true {
      cwd "~"
      command "zsh"
    }
  }
'';
```

### Custom Layouts

Layouts can be:
1. **Inline in Nix** (via `programs.zellij.layouts`)
2. **Separate KDL files** (in `~/.config/zellij/layouts/`)
3. **Project-specific** (`.zellij.kdl` in project root)

### Layout Syntax

#### Basic Structure

```kdl
layout {
  pane {
    // Single pane
  }
}
```

#### Split Panes

```kdl
layout {
  pane split_direction="vertical" {
    pane focus=true {
      size "60%"
    }
    pane {
      size "40%"
    }
  }
}
```

#### Named Panes with Commands

```kdl
layout {
  pane split_direction="vertical" {
    pane {
      name "Editor"
      command "hx"
      args "."
      focus true
    }
    pane {
      name "Server"
      command "npm"
      args "run" "dev"
    }
  }
}
```

#### Multi-Tab Layout

```kdl
layout {
  tab name="Dev" focus=true {
    pane split_direction="vertical" {
      pane
      pane
    }
  }
  tab name="Test" {
    pane
  }
  tab name="Database" {
    pane command="pgcli"
  }
}
```

#### Full Example: Web Development

```kdl
layout {
  tab name="Frontend" focus=true {
    pane split_direction="vertical" {
      pane {
        name "Editor"
        size "65%"
        command "hx"
        args "frontend"
        focus true
      }
      pane split_direction="horizontal" {
        pane {
          name "Dev Server"
          command "npm"
          args "run" "dev"
          cwd "frontend"
        }
        pane {
          name "Tests"
          command "npm"
          args "run" "test:watch"
          cwd "frontend"
        }
      }
    }
  }
  tab name="Backend" {
    pane split_direction="vertical" {
      pane {
        command "cargo"
        args "run"
        cwd "backend"
      }
      pane {
        command "cargo"
        args "test"
        cwd "backend"
      }
    }
  }
  tab name="Database" {
    pane {
      command "pgcli"
      args "myapp_db"
    }
  }
  tab name="Git" {
    pane {
      command "lazygit"
    }
  }
}
```

### Layout Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | string | Display name for pane/tab |
| `focus` | boolean | Start with focus |
| `command` | string | Command to run in pane |
| `args` | string[] | Command arguments |
| `cwd` | string | Working directory |
| `size` | string | Pane size: "50%", "80", etc. |
| `split_direction` | string | "vertical" or "horizontal" |

---

## Shell Integration

### Zsh Functions

Located in `home/common/lib/zsh/functions.zsh`:

#### `zj [session-name]`

```bash
function zj() {
  if [ -n "$ZELLIJ" ]; then
    echo "Already in a Zellij session: $ZELLIJ_SESSION_NAME"
    return 1
  fi
  
  if [ -n "$1" ]; then
    zellij attach -c "$1"
  else
    local session=$(zellij list-sessions 2>/dev/null | fzf --height 40% --header "Select Zellij session:" | awk '{print $1}')
    if [ -n "$session" ]; then
      zellij attach "$session"
    else
      zellij
    fi
  fi
}
```

#### `zjk <session-name|all>`

```bash
function zjk() {
  if [ -z "$1" ]; then
    echo "Usage: zjk <session-name|all>"
    echo "Available sessions:"
    zellij list-sessions 2>/dev/null
    return 1
  fi
  
  if [ "$1" = "all" ]; then
    echo "Killing all Zellij sessions..."
    zellij list-sessions 2>/dev/null | awk '{print $1}' | while read -r session; do
      zellij kill-session "$session" 2>/dev/null && echo "Killed: $session"
    done
  else
    zellij kill-session "$1" && echo "Killed session: $1"
  fi
}
```

#### `zjls`

```bash
function zjls() {
  echo "Active Zellij Sessions:"
  echo "======================"
  zellij list-sessions 2>/dev/null
}
```

#### `zjc`

```bash
function zjc() {
  echo "Cleaning up exited Zellij sessions..."
  local cleaned=0
  zellij list-sessions 2>/dev/null | grep EXITED | awk '{print $1}' | while read -r session; do
    zellij delete-session "$session" 2>/dev/null && {
      echo "Deleted: $session"
      cleaned=$((cleaned + 1))
    }
  done
  if [ $cleaned -eq 0 ]; then
    echo "No exited sessions found."
  else
    echo "Cleaned up $cleaned session(s)."
  fi
}
```

### Shell Aliases

Located in `home/common/shell.nix`:

```nix
shellAliases = {
  zjls = "zellij list-sessions";
  zjk = "zellij kill-session";
  zja = "zellij attach";
  zjd = "zellij delete-session";
  # ... other aliases
};
```

---

## Direnv Integration

### Layout Function

Located in `home/common/shell.nix`:

```bash
# ~/.config/direnv/lib/layout_zellij.sh
layout_zellij() {
  # Don't nest Zellij sessions
  if [ -n "$ZELLIJ" ]; then
    return 0
  fi
  
  # Use directory-based session names for better organization
  local session_name="$(basename "$PWD")"
  
  if [ -f ".zellij.kdl" ]; then
    # Custom layout for this project
    exec zellij --layout .zellij.kdl attach -c "$session_name"
  else
    # Standard layout with named session
    exec zellij attach -c "$session_name"
  fi
}
```

### Usage in Projects

```bash
# In your project directory
cd ~/projects/myapp

# Create .envrc
cat > .envrc << 'EOF'
use nix
layout_zellij
EOF

# Optional: Create custom layout
cat > .zellij.kdl << 'EOF'
layout {
  pane split_direction="vertical" {
    pane focus=true
    pane
  }
}
EOF

# Allow direnv
direnv allow

# Now every time you cd here
cd ~/projects/myapp
# Automatically attaches to "myapp" session!
```

### Behavior

1. **First `cd`:** Creates session named after directory
2. **With `.zellij.kdl`:** Uses custom layout
3. **Without `.zellij.kdl`:** Uses default layout
4. **Already in Zellij:** Does nothing (no nesting)
5. **Leaving directory:** Session persists
6. **Returning:** Reattaches to same session

---

## Customization

### Changing Theme

```nix
# home/common/apps/zellij.nix
settings = lib.mkForce {
  theme = "catppuccin-mocha";  # Change theme
  # ... other settings
};
```

Available themes depend on your Zellij version. Check:
```bash
zellij setup --dump-config | grep -A 20 "themes:"
```

### Changing Default Mode

```nix
settings = lib.mkForce {
  default_mode = "normal";  # Start in normal mode instead of locked
  # ... other settings
};
```

### Adding Custom Layouts

#### Method 1: In Nix Configuration

```nix
# home/common/apps/zellij.nix
programs.zellij = {
  # ... existing config
  
  layouts = {
    default = ''
      layout {
        pane focus=true {
          cwd "~"
          command "zsh"
        }
      }
    '';
    
    # Add new layout
    dev = ''
      layout {
        tab name="Edit" focus=true {
          pane command="hx" args="."
        }
        tab name="Test" {
          pane command="cargo" args="test"
        }
      }
    '';
  };
};
```

Then rebuild: `switch`

Use with: `zellij --layout dev`

#### Method 2: Separate Files

```bash
# Create layout file
mkdir -p ~/.config/zellij/layouts
cat > ~/.config/zellij/layouts/myproject.kdl << 'EOF'
layout {
  tab name="Main" focus=true {
    pane split_direction="vertical" {
      pane
      pane
    }
  }
}
EOF

# Use it
zellij --layout myproject attach -c myproject
```

### Modifying Helper Functions

Edit `home/common/lib/zsh/functions.zsh` and rebuild:

```bash
# Example: Add new helper
function zjr() {
  # Rename current session
  if [ -z "$ZELLIJ" ]; then
    echo "Not in a Zellij session"
    return 1
  fi
  
  if [ -z "$1" ]; then
    echo "Usage: zjr <new-name>"
    return 1
  fi
  
  # Implementation...
}

# Rebuild
switch

# Reload shell
exec zsh
```

### Changing Scroll Buffer Size

```nix
settings = lib.mkForce {
  scroll_buffer_size = 50000;  # Reduce for performance
  # or
  scroll_buffer_size = 200000; # Increase for more history
  # ... other settings
};
```

### Disabling Mouse Support

```nix
settings = lib.mkForce {
  mouse_mode = false;  # Disable mouse
  # ... other settings
};
```

---

## Environment Variables

Zellij sets these environment variables in sessions:

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `ZELLIJ` | Session ID | `0` |
| `ZELLIJ_SESSION_NAME` | Current session name | `myproject` |

Use in scripts:

```bash
if [ -n "$ZELLIJ" ]; then
  echo "Running in Zellij session: $ZELLIJ_SESSION_NAME"
fi
```

---

## File Locations

### Configuration Files

```
~/.config/zellij/
├── config.kdl              # Main config (generated by Nix)
└── layouts/
    ├── default.kdl         # Default layout (generated by Nix)
    └── custom.kdl          # Custom layouts

~/.config/direnv/lib/
└── layout_zellij.sh        # Direnv integration

~/.config/nix/home/common/
├── apps/
│   ├── zellij.nix          # Main Nix module
│   └── zellij-config.kdl   # Keybindings
└── lib/zsh/
    └── functions.zsh       # Shell helpers
```

### Runtime Files

```
~/.cache/zellij/            # Session state
/tmp/zellij-*/              # Socket files
```

---

## Migration from Other Configurations

### From Tmux

| Tmux | Zellij | Notes |
|------|--------|-------|
| `tmux new -s name` | `zj name` | Create/attach session |
| `tmux ls` | `zjls` | List sessions |
| `Ctrl+b %` | `Alt+d` | Split vertical |
| `Ctrl+b "` | `Alt+s` | Split horizontal |
| `Ctrl+b hjkl` | `Alt+hjkl` | Navigate panes |
| `Ctrl+b c` | `Alt+t` | New window/tab |
| `Ctrl+b 0-9` | `Alt+1-9` | Switch window/tab |
| `Ctrl+b d` | Close terminal | Detach |
| `.tmux.conf` | `.zellij.kdl` | Config file |

### From Screen

| Screen | Zellij | Notes |
|--------|--------|-------|
| `screen -S name` | `zj name` | Create session |
| `screen -ls` | `zjls` | List sessions |
| `Ctrl+a c` | `Alt+t` | New window |
| `Ctrl+a n/p` | `Alt+]/[` | Next/prev window |
| `Ctrl+a 0-9` | `Alt+1-9` | Switch window |
| `Ctrl+a d` | Close terminal | Detach |

---

## Related Documentation

- [Zellij Workflow Guide](../guides/zellij-workflow.md) - User guide and patterns
- [Quick Start Guide](../guides/quick-start.md) - Getting started
- [Directory Structure](directory-structure.md) - Config file locations

---

**📍 You are here:** `docs/reference/zellij-config.md` - Zellij configuration reference
