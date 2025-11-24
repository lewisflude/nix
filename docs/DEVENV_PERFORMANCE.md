# Devenv and Direnv Performance Optimization Guide

This guide addresses slow loading times and unresponsive zsh shells when using devenv or direnv.

## Common Performance Issues

### Symptoms
- Shell becomes unresponsive during environment loading
- Long delays (5-30+ seconds) when entering directories with `.envrc` or `devenv.nix`
- Zsh freezes while direnv/devenv initializes
- High CPU usage during environment activation

## Root Causes

1. **Nix evaluation blocking shell** - Flake evaluation happens synchronously
2. **Too many packages** - Large package sets slow down PATH setup
3. **Heavy shell hooks** - Expensive operations in shell hooks
4. **Cache misses** - Missing binary cache hits causing builds
5. **Network timeouts** - Slow cache queries blocking initialization

## Optimizations

### 1. Direnv Configuration (This Repository)

#### Current Configuration
- ✅ `nix-direnv.enable = true` - Already enabled (provides caching)
- ✅ `DIRENV_LOG_FORMAT = ""` - Already set (reduces output)

#### Additional Optimizations

Add these environment variables to speed up direnv:

```nix
# In home/common/apps/direnv.nix or home/common/features/core/shell.nix
sessionVariables = {
  DIRENV_LOG_FORMAT = "";  # Already set
  DIRENV_WARN_TIMEOUT = "20s";  # Warn if direnv takes > 20s
  DIRENV_TIMEOUT = "5s";  # Fail fast if direnv hangs
};
```

### 2. Devenv-Specific Optimizations

#### In Your Project's `devenv.nix`

**Lazy Service Loading:**
```nix
# Only start services when explicitly requested
services.postgres.enable = lib.mkDefault false;
services.redis.enable = lib.mkDefault false;

# Start services manually: devenv shell --start
```

**Minimize Package Count:**
```nix
# Instead of loading everything upfront
packages = [ pkgs.nodejs pkgs.python3 pkgs.rustc ];

# Use process-compose or scripts to load tools on-demand
```

**Use Devenv's Caching:**
```nix
# Enable devenv's built-in caching
devenv.cache.enable = true;
```

#### In Your Project's `.envrc` (for devenv)

```bash
# Use devenv's optimized loader
if ! command -v devenv &> /dev/null; then
  eval "$(devenv hook zsh)"
fi

# Or use direnv with devenv
if [ -f devenv.nix ]; then
  use devenv
fi
```

### 3. Shell Hook Optimization

#### Avoid Heavy Operations in Shell Hooks

**❌ Bad:**
```nix
shellHook = ''
  # This runs every time you enter the shell
  npm install  # Slow!
  cargo build  # Very slow!
  echo "Building..."
'';
```

**✅ Good:**
```nix
shellHook = ''
  # Only show status, don't build
  echo "🚀 Development environment ready"
  echo "Run 'npm install' or 'cargo build' when needed"
'';
```

### 4. Nix Flake Evaluation Optimization

#### Use `nix-direnv` (Already Enabled)

The `nix-direnv` package provides:
- Automatic caching of flake evaluations
- Faster subsequent loads
- Reduced Nix daemon overhead

#### Optimize `.envrc` Files

**❌ Slow:**
```bash
# This evaluates the entire flake every time
use flake ~/.config/nix#nextjs
```

**✅ Faster (if using devenv):**
```bash
# devenv has its own caching
use devenv
```

**✅ Fastest (specific shell):**
```bash
# Only load what you need
use flake ~/.config/nix#nextjs --no-write-lock-file
```

### 5. Environment Variable Optimization

Add these to reduce blocking:

```nix
# In home/common/features/core/shell.nix
sessionVariables = {
  # Direnv optimizations
  DIRENV_LOG_FORMAT = "";  # Suppress verbose output
  DIRENV_WARN_TIMEOUT = "20s";  # Warn on slow loads
  DIRENV_TIMEOUT = "5s";  # Fail fast on hangs
  
  # Nix optimizations (if not already set)
  NIX_BUILD_CORES = "0";  # Use all cores
  NIX_CONF_DIR = "${config.home.homeDirectory}/.config/nix";
};
```

### 6. Zsh Integration Optimization

#### Lazy Load Direnv Hook

Instead of loading direnv immediately, load it on first use:

```zsh
# In your zsh config
if command -v direnv &> /dev/null; then
  # Lazy load direnv
  _direnv_hook() {
    eval "$(direnv hook zsh)"
    direnv "$@"
  }
  alias direnv=_direnv_hook
fi
```

**Note**: This repository already uses Home Manager's `enableZshIntegration`, which is optimized.

### 7. Project-Specific Optimizations

#### For Projects Using Devenv

Create a `.devenvrc` file in your project root:

```bash
# .devenvrc
export DEVENV_PROFILE="${DEVENV_PROFILE:-default}"
export DEVENV_CACHE_DIR="${HOME}/.cache/devenv"
```

#### Minimize Devenv.nix Complexity

**❌ Slow:**
```nix
# Loading many heavy packages
packages = [
  pkgs.nodejs_20
  pkgs.python311
  pkgs.rustc
  pkgs.go
  pkgs.postgresql_16
  pkgs.redis
  # ... many more
];
```

**✅ Faster:**
```nix
# Load only what's needed, use system packages when possible
packages = [
  pkgs.nodejs_20  # Only if not in system
  # Use system python/rust when available
];

# Start services on-demand
scripts.start-dev.exec = ''
  devenv up &
'';
```

## Quick Fixes

### Immediate Actions

1. **Add timeout to direnv:**
   ```bash
   export DIRENV_WARN_TIMEOUT="20s"
   export DIRENV_TIMEOUT="5s"
   ```

2. **Check for slow shell hooks:**
   ```bash
   # In your devenv.nix or shell.nix, look for:
   # - npm install
   # - cargo build
   # - pip install
   # - Any network operations
   ```

3. **Use devenv's profile system:**
   ```bash
   # Load only specific profiles
   devenv shell --profile minimal
   ```

4. **Clear direnv cache if corrupted:**
   ```bash
   rm -rf ~/.cache/nix-direnv
   ```

### Diagnostic Commands

```bash
# Time direnv loading
time direnv allow

# Check what's being loaded
direnv status

# Profile devenv loading
DEVENV_DEBUG=1 devenv shell

# Check nix-direnv cache
ls -lh ~/.cache/nix-direnv
```

## Configuration Updates

### Update direnv.nix

Add timeout and performance settings:

```nix
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    
    # Performance optimizations
    config = {
      global = {
        warn_timeout = "20s";
        timeout = "5s";
      };
    };
  };
}
```

### Update shell.nix Session Variables

Add direnv performance variables:

```nix
sessionVariables = {
  DIRENV_LOG_FORMAT = "";
  DIRENV_WARN_TIMEOUT = "20s";
  DIRENV_TIMEOUT = "5s";
};
```

## Expected Improvements

After applying these optimizations:

- **First load**: 5-15 seconds (flake evaluation)
- **Subsequent loads**: 0.5-2 seconds (cached)
- **Shell responsiveness**: Immediate (no blocking)

## Troubleshooting

### Still Slow?

1. **Check flake evaluation time:**
   ```bash
   time nix flake check
   ```

2. **Profile direnv:**
   ```bash
   DIRENV_LOG_FORMAT="%s" direnv allow
   ```

3. **Check for network issues:**
   ```bash
   nix store ping
   ```

4. **Verify nix-direnv cache:**
   ```bash
   ls -lh ~/.cache/nix-direnv | head -20
   ```

### Zsh Still Unresponsive?

1. **Check shell hooks:**
   ```bash
   # Look for heavy operations in:
   # - devenv.nix shellHook
   # - .envrc
   # - zsh initialization files
   ```

2. **Disable direnv temporarily:**
   ```bash
   direnv deny
   # Test if shell is responsive
   ```

3. **Check for infinite loops:**
   ```bash
   # Look for recursive direnv calls
   grep -r "direnv" .envrc devenv.nix
   ```

## References

- [Devenv Performance Guide](https://devenv.sh/guides/performance/)
- [Direnv Performance Tips](https://direnv.net/)
- [Nix Performance Tuning](./PERFORMANCE_TUNING.md)
