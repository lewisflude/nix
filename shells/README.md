# Development Shells

This directory contains Nix development shells for various languages and project types.

## ??? Design Philosophy: Layered Hybrid Approach

This configuration uses a **two-layer architecture** to balance convenience with flexibility:

### Layer 1: System-Wide Tooling (Core Daily Drivers)

Defined in `hosts/_common/features.nix`:

```nix
development = {
  rust = true;    # Rust toolchain always available
  python = true;  # Python toolchain always available
  node = true;    # Node.js toolchain always available
  go = false;     # Only via dev shells
}
```

**These languages are installed system-wide because:**
- ? You use them constantly across all projects
- ? Enables quick experiments and scratch scripts
- ? LSPs always available for editor integration
- ? No ceremony for one-off tasks like `python -c "..."`

### Layer 2: Dev Shells (Extensions & Overrides)

Dev shells in this directory are **ADDITIVE**, not replacements:
- They extend system tooling with project-specific additions
- They configure environment variables and aliases
- They only reinstall language runtimes when version overrides are needed

## ?? Directory Structure

```
shells/
??? default.nix           # Exports all available shells
??? projects/             # Project-specific environments
?   ??? nextjs.nix        # Next.js projects
?   ??? api-backend.nix   # API backend with databases
?   ??? react-native.nix  # React Native mobile apps
?   ??? qmk.nix           # QMK keyboard firmware
?   ??? development.nix   # General development
??? envrc-templates/      # .envrc templates for direnv
??? utils/                # Shell utilities
```

## ?? Shell Categories

### Project-Specific Shells

These shells add project-specific tools and configuration:

#### `nextjs` - Next.js Development
```bash
nix develop .#nextjs
```
- **Adds:** Tailwind CSS language server
- **Uses from system:** Node.js, TypeScript, pnpm
- **Configures:** Project aliases (dev, build, lint)

#### `api-backend` - API Backend Development
```bash
nix develop .#api-backend
```
- **Adds:** PostgreSQL, Redis, HTTP clients (curl, httpie, jq)
- **Uses from system:** Node.js, TypeScript, pnpm
- **Configures:** Database URLs, auto-starts PostgreSQL

#### `react-native` - React Native Mobile Development
```bash
nix develop .#react-native
```
- **Adds:** Watchman, CocoaPods (macOS), xcbuild (macOS)
- **Uses from system:** Node.js, TypeScript, pnpm
- **Configures:** React Native CLI aliases, environment variables

#### `qmk` - QMK Keyboard Firmware
```bash
nix develop .#qmk
```
- **Complete environment:** QMK tools, ARM GCC, DFU utilities
- **Self-contained:** Includes all necessary tooling

### Language Shells

For languages NOT in your system defaults:

#### `go` - Go Development
```bash
nix develop .#go
```
- **Provides:** Go toolchain, gopls, golangci-lint, delve
- **Reason:** Go is disabled by default in system config

#### `web` - Web Development (HTML/CSS/Sass)
```bash
nix develop .#web
```
- **Adds:** Tailwind CSS language server, html-tidy, sass
- **Uses from system:** Node.js, TypeScript

#### `devops` - DevOps Tools
```bash
nix develop .#devops
```
- **Provides:** kubectl, OpenTofu, Terragrunt, k9s, cloud CLIs
- **Specialized:** Complete DevOps toolset

#### `love2d` - Love2D Game Development (Linux only)
```bash
nix develop .#love2d
```
- **Provides:** Love2D, Lua, Lua LSP, formatters, linters
- **Complete environment:** Full game development setup

## ?? Usage Patterns

### With direnv (Recommended)

Create a `.envrc` in your project:

```bash
# For Next.js projects
use flake ~/.config/nix#nextjs

# For API backends
use flake ~/.config/nix#api-backend

# For React Native
use flake ~/.config/nix#react-native
```

Then run `direnv allow` and the shell loads automatically when you `cd` into the directory.

### Manual Activation

```bash
# Enter a shell
nix develop ~/.config/nix#nextjs

# Or if you're in this directory
nix develop .#nextjs
```

### One-off Commands

```bash
# Run a command in a shell without entering it
nix develop .#devops --command kubectl get pods
```

## ?? When to Use Each Approach

### Use System-Wide (Already Configured)
? Daily-driver languages (Node.js, Python, Rust)  
? Tools you use across all projects  
? LSPs and formatters for your main languages  

### Use Dev Shells
? Project-specific dependencies (databases, services)  
? Non-default languages (Go, Lua, etc.)  
? Version overrides (need Node 18 when system has Node 20)  
? Project environment configuration  
? Team collaboration (share shell via flake.nix)  

### When to Override Versions

**Only reinstall language runtimes in shells when:**

1. **Project requires specific version:**
```nix
# Project needs Node 18, system has Node 20
pkgs.mkShell {
  buildInputs = [ pkgs.nodejs_18 ];  # Explicit override
}
```

2. **Testing across multiple versions:**
```nix
# Matrix testing shell
pkgs.mkShell {
  buildInputs = [ pkgs.python311 pkgs.python312 pkgs.python313 ];
}
```

3. **Contributing to project with pinned version:**
```nix
# Open source project specifies exact versions
pkgs.mkShell {
  buildInputs = [ pkgs.nodejs_20 pkgs.pnpm ];
}
```

## ?? Creating New Shells

### For Project-Specific Work

```nix
# shells/projects/my-project.nix
{ pkgs, lib, system, ... }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # System provides: node, python, rust (if enabled)
    # Add ONLY project-specific tools
    postgresql
    my-special-tool
  ];
  
  shellHook = ''
    echo "?? My Project environment loaded (using system tooling)"
    
    # Project aliases
    alias dev="npm run dev"
    
    # Environment variables
    export MY_VAR="value"
  '';
}
```

### For New Languages

```nix
# shells/default.nix - add to devShellsCommon
kotlin = pkgs.mkShell {
  buildInputs = with pkgs; [
    kotlin
    kotlin-language-server
    gradle
  ];
  shellHook = ''
    echo "?? Kotlin environment loaded"
  '';
};
```

## ?? Checking What's Available

### List all shells
```bash
nix flake show | grep devShells
```

### Check what's in a shell
```bash
nix develop .#nextjs --command env | grep -E "(PATH|NODE)"
```

### Compare shell vs system
```bash
# In shell
which node && node --version

# Exit shell
exit

# System
which node && node --version
```

## ?? Best Practices

1. **Don't duplicate system tooling** - If it's in your system config, use it
2. **Be explicit about overrides** - Comment why you're overriding a version
3. **Keep shells focused** - One clear purpose per shell
4. **Document project-specific setup** - Use shellHook for instructions
5. **Use direnv for automation** - Set up `.envrc` in project directories
6. **Test shells regularly** - Ensure they still work after system updates

## ?? Quick Reference

| Shell | Purpose | Key Tools |
|-------|---------|-----------|
| `nextjs` | Next.js apps | tailwindcss-ls |
| `api-backend` | API services | PostgreSQL, Redis |
| `react-native` | Mobile apps | Watchman, CocoaPods |
| `qmk` | Keyboard firmware | QMK, ARM tools |
| `go` | Go projects | Go toolchain |
| `web` | Web frontend | HTML/CSS tools |
| `devops` | Infrastructure | kubectl, Terraform |
| `love2d` | Game dev (Linux) | Love2D, Lua |

## ?? Further Reading

- [Nix Dev Shells Documentation](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-develop.html)
- [direnv with Nix](https://github.com/nix-community/nix-direnv)
- [Project Development with Nix](https://nix.dev/tutorials/first-steps/dev-environment)

## ?? Contributing

When adding new shells:
1. Follow the additive pattern (extend, don't replace system tooling)
2. Document the purpose and key tools
3. Add examples to this README
4. Test on both NixOS and Darwin if applicable
