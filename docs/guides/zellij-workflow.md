# Zellij Workflow Guide

A comprehensive guide to using Zellij terminal multiplexer effectively in your Nix configuration.

## 📖 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Workflow Patterns](#workflow-patterns)
- [Keybindings Reference](#keybindings-reference)
- [Session Management](#session-management)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

---

## Overview

### What is Zellij?

Zellij is a modern terminal multiplexer that allows you to:
- Run multiple terminal sessions in one window
- Create persistent sessions that survive terminal closures
- Split terminals into panes and organize them in tabs
- Detach and reattach to sessions from anywhere

### Why Use Zellij?

In this configuration, Zellij complements your three-layer window management:

```
┌─────────────────────────────────────────────┐
│ Niri (Window Manager)                       │
│ • High-level project/app organization      │
│ • Mod+1-9: Switch workspaces               │
└─────────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ Ghostty (Terminal Emulator)                │
│ • Terminal windows in Niri                 │
│ • Mod+T: New terminal window               │
└─────────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ Zellij (Terminal Multiplexer)              │
│ • Terminal session management              │
│ • Alt+hjkl: Navigate panes                 │
│ • Alt+1-9: Switch tabs                     │
└─────────────────────────────────────────────┘
```

---

## Architecture

### Configuration Location

All Zellij configuration is managed declaratively through Nix:

- **Main config:** `home/common/apps/zellij.nix`
- **Keybindings:** `home/common/apps/zellij-config.kdl`
- **Shell integration:** `home/common/shell.nix`
- **Helper functions:** `home/common/lib/zsh/functions.zsh`

### Integration Points

1. **Home Manager Module:** Declarative configuration via `programs.zellij`
2. **Zsh Integration:** Auto-completion and helper functions
3. **Direnv Integration:** Automatic session attachment per directory
4. **Ghostty Integration:** Optional terminal launch with Zellij

---

## Getting Started

### Basic Commands

#### Starting Zellij

```bash
# Smart launcher with session picker
zj

# Launch/attach to a named session
zj myproject

# Start Zellij without a session name (generates random name)
zellij
```

#### Listing Sessions

```bash
# Show all active sessions
zjls

# Or use the full command
zellij list-sessions
```

#### Attaching to Sessions

```bash
# Attach to existing session or create it
zja session-name

# Attach to session (full command)
zellij attach session-name
```

### First Session

Let's create your first Zellij session:

```bash
# 1. Start a named session
zj my-first-session

# 2. You're now in Zellij! Try these:
#    - Press Alt+d to split right
#    - Press Alt+s to split down
#    - Press Alt+h/j/k/l to navigate between panes
#    - Press Alt+t to create a new tab
#    - Press Alt+q to quit

# 3. Close the terminal (Mod+Q) - session stays alive!

# 4. Reattach later from any terminal
zj my-first-session
```

---

## Workflow Patterns

### Pattern 1: Project-Based Sessions ⭐ **RECOMMENDED**

Use one Zellij session per project for persistent context:

```bash
# Frontend project
zj frontend-app
# Tab 1: npm run dev
# Tab 2: npm run test:watch
# Tab 3: git operations

# Backend project
zj backend-api
# Tab 1: cargo run
# Tab 2: cargo test
# Tab 3: database shell

# NixOS configuration
zj nix-config
# Tab 1: helix editor
# Tab 2: build/test
# Tab 3: git
```

**Benefits:**
- ✅ Context preserved between terminal sessions
- ✅ Easy to switch between projects
- ✅ Each project has its own layout
- ✅ No mixing of unrelated work

---

### Pattern 2: Workspace + Session Mapping

Combine Niri workspaces with Zellij sessions:

```bash
# Workspace 1: Main Development
Mod+1                    # Switch to workspace 1
Mod+T                    # Open Ghostty (if not open)
zj main-project         # Your main work session

# Workspace 2: Side Project
Mod+2                    # Switch to workspace 2
Mod+T                    # Another Ghostty window
zj side-project         # Different context

# Workspace 3: Monitoring
Mod+3                    # Dedicated monitoring workspace
Mod+T
zj monitor
# Tab 1: htop
# Tab 2: lazydocker
# Tab 3: system logs
```

**Benefits:**
- ✅ Physical separation of contexts (workspaces)
- ✅ Logical organization within contexts (sessions)
- ✅ Fast context switching (Mod+number)

---

### Pattern 3: Direnv Auto-Sessions

For projects with `.envrc`, Zellij automatically attaches:

```bash
# 1. Add layout_zellij to your project
cd ~/projects/myapp
echo "layout_zellij" >> .envrc
direnv allow

# 2. Every time you cd into this directory
cd ~/projects/myapp
# Automatically: zj myapp

# 3. Leave the directory
cd ~
# Session persists, ready for next time

# 4. Return later
cd ~/projects/myapp
# Reattaches to the same session!
```

**Perfect for:**
- Development projects
- Long-running processes
- Maintaining project-specific context

---

### Pattern 4: Custom Project Layouts

Create `.zellij.kdl` for complex project setups:

```bash
# Example: Full-stack development layout
cd ~/projects/webapp
cat > .zellij.kdl << 'EOF'
layout {
  pane split_direction="vertical" {
    pane focus=true {
      name "Frontend"
      command "npm"
      args "run" "dev"
      cwd "frontend"
    }
    pane split_direction="horizontal" {
      pane {
        name "Backend"
        command "cargo"
        args "run"
        cwd "backend"
      }
      pane {
        name "Database"
        command "pgcli"
        args "myapp_db"
      }
    }
  }
}
EOF

# Add to .envrc
echo "layout_zellij" >> .envrc
direnv allow

# Next time you enter the directory
cd ~/projects/webapp
# Boom! Full environment ready
```

---

### Pattern 5: Role-Based Sessions

Create specialized sessions for different tasks:

```bash
# Development session
zj dev
  Alt+1 → Editor tab
  Alt+2 → Build/test tab
  Alt+3 → Git operations

# Database session
zj db
  Alt+1 → PostgreSQL (pgcli)
  Alt+2 → Database logs
  Alt+3 → Backup scripts

# Docker/Infrastructure
zj infra
  Alt+1 → docker-compose logs
  Alt+2 → lazydocker
  Alt+3 → kubectl

# Quick scratch work
zj scratch
  # Temporary session for one-off tasks
  # Delete when done: zjk scratch
```

---

### Pattern 6: Long-Running Processes

Keep processes running even when terminal closes:

```bash
# 1. Start server in a session
zj api-server
npm run dev              # Server starts

# 2. Detach by closing terminal
Mod+Q                    # Close Ghostty window
# Server keeps running in background!

# 3. Later, check on it
zj api-server           # Reattach
# Server still running with all logs

# 4. When done
Alt+q                    # Quit Zellij (stops processes)
```

---

## Keybindings Reference

### Navigation (Normal Mode)

| Key | Action | Description |
|-----|--------|-------------|
| `Alt+h` | Focus Left | Move to pane on the left |
| `Alt+j` | Focus Down | Move to pane below |
| `Alt+k` | Focus Up | Move to pane above |
| `Alt+l` | Focus Right | Move to pane on the right |

### Pane Management

| Key | Action | Description |
|-----|--------|-------------|
| `Alt+d` | New Pane Right | Split current pane vertically |
| `Alt+s` | New Pane Down | Split current pane horizontally |
| `Alt+n` | New Pane | Create floating pane |
| `Alt+w` | Close Pane | Close current pane |
| `Alt+f` | Fullscreen | Toggle pane fullscreen |

### Pane Resizing

| Key | Action | Description |
|-----|--------|-------------|
| `Alt+H` | Resize Left | Increase pane size left |
| `Alt+J` | Resize Down | Increase pane size down |
| `Alt+K` | Resize Up | Increase pane size up |
| `Alt+L` | Resize Right | Increase pane size right |

### Tab Management

| Key | Action | Description |
|-----|--------|-------------|
| `Alt+t` | New Tab | Create a new tab |
| `Alt+1-9` | Go to Tab N | Jump to tab number |
| `Alt+[` | Previous Tab | Go to previous tab |
| `Alt+]` | Next Tab | Go to next tab |
| `Alt+r` | Rename Tab | Rename current tab |

### Session Management

| Key | Action | Description |
|-----|--------|-------------|
| `Alt+o` | Session Mode | Enter session management mode |
| `Alt+q` | Quit | Quit Zellij (closes session) |

### Scroll/Search Mode

| Key | Action | Description |
|-----|--------|-------------|
| `Alt+/` | Scroll Mode | Enter scroll/search mode |
| `j` / `Down` | Scroll Down | Scroll down one line |
| `k` / `Up` | Scroll Up | Scroll up one line |
| `d` | Half Page Down | Scroll down half page |
| `u` | Half Page Up | Scroll up half page |
| `g` | Top | Jump to top |
| `G` | Bottom | Jump to bottom |
| `/` | Search | Enter search mode |
| `Esc` | Normal Mode | Exit scroll mode |

### Locked Mode

| Key | Action | Description |
|-----|--------|-------------|
| `Ctrl+g` | Unlock | Return to normal mode |

> **Note:** Locked mode is the default! This prevents Zellij from interfering with vim, helix, or other terminal applications. Press `Ctrl+g` to unlock when you need Zellij commands.

---

## Session Management

### Shell Helpers

These custom functions are available in your zsh shell:

#### `zj [session-name]`

Smart Zellij launcher with fzf integration.

```bash
# Interactive session picker
zj

# Launch/attach to named session
zj myproject

# From within a session
zj
# Error: Already in a Zellij session: current-session
```

#### `zjls`

Better formatted session list.

```bash
zjls
# Output:
# Active Zellij Sessions:
# ======================
# main-project [Created 2h 15m ago]
# side-project [Created 45m ago] (current)
# monitor [Created 3h 1m ago]
```

#### `zjk <session-name|all>`

Kill Zellij sessions.

```bash
# Kill specific session
zjk old-session

# Kill all sessions (nuclear option)
zjk all

# Without arguments, shows usage
zjk
# Usage: zjk <session-name|all>
# Available sessions:
# ...
```

#### `zjc`

Clean up exited sessions.

```bash
zjc
# Output:
# Cleaning up exited Zellij sessions...
# Deleted: old-session-1
# Deleted: temp-session
# Cleaned up 2 session(s).
```

### Shell Aliases

Quick shortcuts for common commands:

```bash
zjls          # zellij list-sessions
zjk           # zellij kill-session
zja           # zellij attach
zjd           # zellij delete-session
```

### Session Lifecycle

#### Creating Sessions

```bash
# Explicit session creation
zellij attach -c myproject

# Via helper (recommended)
zj myproject

# Auto-created via direnv
cd ~/projects/myapp  # Has .envrc with layout_zellij
```

#### Detaching Sessions

Sessions persist when you close the terminal:

```bash
# Method 1: Close terminal
Mod+Q                    # Closes Ghostty, session persists

# Method 2: Exit shell (if single pane)
exit

# Method 3: Quit Zellij (kills session)
Alt+q
```

#### Reattaching Sessions

```bash
# Interactive picker
zj

# Direct attach
zj myproject

# Full command
zellij attach myproject
```

#### Deleting Sessions

```bash
# Clean up exited sessions
zjc

# Kill specific session
zjk myproject

# Delete all sessions
zjk all
```

---

## Advanced Usage

### Custom Layouts

#### Simple Layout Example

```kdl
layout {
  pane split_direction="vertical" {
    pane focus=true
    pane
  }
}
```

#### Complex Development Layout

```kdl
layout {
  pane split_direction="vertical" {
    pane focus=true {
      size "60%"
      command "hx"
      args "."
    }
    pane split_direction="horizontal" {
      pane {
        name "Build"
        command "npm"
        args "run" "dev"
      }
      pane {
        name "Test"
        command "npm"
        args "run" "test:watch"
      }
      pane {
        name "Git"
      }
    }
  }
}
```

#### Multi-Tab Layout

```kdl
layout {
  tab name="Dev" focus=true {
    pane split_direction="vertical" {
      pane command="hx" args="."
      pane command="npm" args="run" "dev"
    }
  }
  tab name="Test" {
    pane command="npm" args="run" "test:watch"
  }
  tab name="Database" {
    pane command="pgcli" args="myapp_db"
  }
}
```

### Project Templates

Create reusable layout templates:

```bash
# Create layouts directory
mkdir -p ~/.config/zellij/layouts

# Create a template
cat > ~/.config/zellij/layouts/fullstack.kdl << 'EOF'
layout {
  tab name="Frontend" focus=true {
    pane split_direction="vertical" {
      pane command="npm" args="run" "dev" cwd="frontend"
      pane command="npm" args="run" "test:watch" cwd="frontend"
    }
  }
  tab name="Backend" {
    pane command="cargo" args="run" cwd="backend"
  }
  tab name="Database" {
    pane command="pgcli" args="myapp_db"
  }
}
EOF

# Use the template
zellij --layout fullstack attach -c myproject
```

### Integration with Development Tools

#### With Git Worktrees

```bash
# Main project
zj main-project
cd ~/projects/myapp

# Feature branch in worktree
zj feature-new-ui
cd ~/projects/myapp-worktrees/feature-new-ui

# Each worktree gets its own session!
```

#### With Docker Compose

```bash
zj docker-project
# Tab 1: docker-compose up
# Tab 2: lazydocker (TUI)
# Tab 3: docker logs -f container-name

Alt+1  # View compose output
Alt+2  # Manage with lazydocker
Alt+3  # Monitor specific container
```

#### With Language Servers

```bash
# Python development
zj python-project
# Tab 1: hx . (Helix with LSP)
# Tab 2: python -m pytest --watch
# Tab 3: ipython (REPL)

# Rust development
zj rust-project
# Tab 1: hx . (Helix with rust-analyzer)
# Tab 2: cargo watch -x test
# Tab 3: cargo run
```

### Session Persistence

Zellij automatically saves session state with `session_serialization = true`:

```bash
# Start work
zj myproject
# Create tabs, split panes, set up environment
# ...close terminal...

# Later
zj myproject
# Layout restored exactly as you left it!
```

### Remote Sessions

Use Zellij over SSH:

```bash
# SSH into remote server
ssh myserver

# Start/attach to session on remote
zj remote-work

# Work normally with Alt+hjkl, Alt+1-9, etc.

# Close SSH connection
exit
# Session persists on remote server

# Reconnect later
ssh myserver
zj remote-work
# Pick up where you left off
```

---

## Troubleshooting

### Too Many Sessions

**Problem:** Running `zjls` shows 20+ sessions

**Solution:**
```bash
# Clean up exited sessions
zjc

# Review active sessions
zjls

# Kill old/unused sessions
zjk old-session-1
zjk temp-session

# Nuclear option (careful!)
zjk all
```

**Prevention:**
- Name sessions meaningfully
- Use `zj session-name` instead of bare `zellij`
- Run `zjc` weekly
- Kill scratch sessions when done

---

### Session Already Exists Error

**Problem:** `zj myproject` says "already in session"

**Solution:**
```bash
# Check if you're already in Zellij
echo $ZELLIJ
# If output: "0" (or any number), you're in a session

# Exit current session first
exit              # or
Alt+q            # quit Zellij

# Then attach to desired session
zj myproject
```

---

### Keybindings Not Working

**Problem:** Alt+h/j/k/l don't work

**Solution:**

1. **Check if in locked mode:**
   ```
   # Press Ctrl+g to unlock
   # Default mode is locked to not interfere with vim/helix
   ```

2. **Check terminal emulation:**
   - Ghostty should handle Alt keys correctly
   - If using other terminal, verify Alt key settings

3. **Verify configuration is applied:**
   ```bash
   # Rebuild system
   switch
   
   # Check config location
   ls -la ~/.config/zellij/config.kdl
   ```

---

### Panes/Tabs Disappearing

**Problem:** Created panes but they vanish on reattach

**Solution:**

Panes with completed processes close automatically:

```bash
# Bad: Pane closes when command finishes
Alt+d              # Split pane
ls                # Command finishes, pane closes

# Good: Keep pane alive with shell
Alt+d              # Split pane
# Just use it as a shell, pane stays open

# Or: Use for long-running process
Alt+d
npm run dev       # Stays open while running
```

---

### Can't Close Zellij

**Problem:** Closing terminal doesn't stop session

**This is a feature!** Sessions persist by design.

**To actually close a session:**
```bash
# Method 1: Quit from inside
Alt+q

# Method 2: Kill from outside
zjk session-name

# Method 3: Delete session
zellij delete-session session-name
```

---

### Ghostty Always Starts Zellij

**Problem:** Every new terminal starts in Zellij automatically

**Solution:**

This was removed in the configuration! If you still see this:

```nix
# In home/common/terminal.nix, ensure this is commented out:
programs.ghostty.settings = {
  # initial-command = "zellij attach -c default";  # ← Should be commented
};
```

Then rebuild: `switch`

---

### Conflicts with Niri Keybindings

**Problem:** Alt+1-9 not working in Zellij

**This should not happen!** Your configuration uses:
- **Niri:** `Mod+1-9` (Super/Windows key)
- **Zellij:** `Alt+1-9` (Alt key)

If you experience conflicts:
1. Verify you're pressing Alt, not Mod
2. Check if other app is capturing Alt keys
3. Test in plain Ghostty without other apps

---

### Direnv Not Auto-Starting Zellij

**Problem:** `cd project && layout_zellij` doesn't work

**Solution:**

1. **Verify direnv is working:**
   ```bash
   cd ~/projects/myapp
   # Should see: direnv: loading .envrc
   ```

2. **Check .envrc content:**
   ```bash
   cat .envrc
   # Should contain: layout_zellij
   ```

3. **Allow direnv:**
   ```bash
   direnv allow
   ```

4. **Verify layout function exists:**
   ```bash
   type layout_zellij
   # Should show function definition
   ```

5. **Rebuild if needed:**
   ```bash
   switch
   # Restart shell
   exec zsh
   ```

---

## Best Practices

### Session Naming

✅ **Good names:**
```bash
zj frontend-app
zj backend-api
zj nix-config
zj customer-dashboard
```

❌ **Bad names:**
```bash
zj test
zj temp
zj session1
zj asdf
```

### Session Organization

**Recommended session count:** 3-7 active sessions

**Good setup:**
- 1-2 main work projects
- 1 monitoring session (always-on)
- 1 system/config session
- 1-2 side projects
- 1 scratch session (temporary)

**Avoid:**
- 20+ sessions (confusing)
- Generic names (which "test"?)
- Nested sessions (Zellij in Zellij)

### Tab Organization

**Within a session, organize by task:**

```bash
zj myproject
  Alt+1 → Editor/main work
  Alt+2 → Build/dev server
  Alt+3 → Tests
  Alt+4 → Git operations
  Alt+5 → Database/REPL
```

### Cleanup Routine

**Daily:**
- Kill scratch sessions when done: `zjk scratch`

**Weekly:**
- Run `zjc` to clean exited sessions
- Review `zjls` and kill unused sessions

**Monthly:**
- Review all sessions: `zjls`
- Kill anything not actively used
- Consider `zjk all` and fresh start

---

## Quick Reference Card

```
╔══════════════════════════════════════════════════════════╗
║               ZELLIJ QUICK REFERENCE                     ║
╠══════════════════════════════════════════════════════════╣
║ STARTING                                                 ║
║  zj [name]        Smart launcher / attach                ║
║  zjls             List sessions                          ║
║  zjk <name|all>   Kill session(s)                        ║
║  zjc              Clean exited sessions                  ║
╠══════════════════════════════════════════════════════════╣
║ NAVIGATION (in session)                                  ║
║  Alt+h/j/k/l      Focus pane (vim-style)                 ║
║  Alt+1-9          Jump to tab                            ║
║  Alt+[/]          Previous/next tab                      ║
╠══════════════════════════════════════════════════════════╣
║ PANE MANAGEMENT                                          ║
║  Alt+d            Split right                            ║
║  Alt+s            Split down                             ║
║  Alt+w            Close pane                             ║
║  Alt+f            Fullscreen toggle                      ║
║  Alt+H/J/K/L      Resize pane                           ║
╠══════════════════════════════════════════════════════════╣
║ TAB MANAGEMENT                                           ║
║  Alt+t            New tab                                ║
║  Alt+r            Rename tab                             ║
╠══════════════════════════════════════════════════════════╣
║ SESSION                                                  ║
║  Alt+o            Session mode                           ║
║  Alt+q            Quit Zellij                            ║
║  Alt+/            Scroll mode                            ║
║  Ctrl+g           Unlock (from locked mode)              ║
╚══════════════════════════════════════════════════════════╝
```

---

## Examples

### Example 1: Web Development

```bash
zj webapp
Alt+t  # New tab
Alt+1  # Tab 1: "Frontend"
cd frontend && npm run dev

Alt+t  # New tab
Alt+2  # Tab 2: "Backend"
cd backend && cargo run

Alt+t  # New tab
Alt+3  # Tab 3: "Tests"
cd frontend && npm run test:watch

Alt+t  # New tab
Alt+4  # Tab 4: "Git"
# For git operations

Alt+1  # Back to frontend dev
```

### Example 2: DevOps Work

```bash
zj infra
Alt+d  # Split right
# Left: kubectl logs
# Right: kubectl get pods --watch

Alt+t  # New tab
Alt+2
docker-compose logs -f

Alt+t  # New tab
Alt+3
lazydocker
```

### Example 3: NixOS Configuration

```bash
cd ~/.config/nix
# Direnv auto: zj nix-config

Alt+1  # Main editing
hx modules/nixos/...

Alt+t
Alt+2  # Build tab
nh os build

Alt+t
Alt+3  # Git tab
git status
git diff

Alt+1  # Back to editing
```

---

## Related Documentation

- [Quick Start Guide](quick-start.md) - Getting started with the config
- [Niri Keyboard Config](keyboard-niri.md) - Window manager keybindings
- [Directory Structure](../reference/directory-structure.md) - Where configs live

---

**📍 You are here:** `docs/guides/zellij-workflow.md` - Zellij terminal multiplexer guide
