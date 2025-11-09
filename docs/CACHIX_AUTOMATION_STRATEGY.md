# Cachix Automation Strategy

This document outlines when and how to automatically cache builds using Cachix and devour-flake.

## ?? When to Auto-Run Caching

### ? **Recommended: CI/CD Workflows**

**When**: On every push/PR to main branch, or on successful builds

**Why**:

- CI builds are already slow - caching makes them much faster
- Multiple developers benefit from shared cache
- No user interaction needed
- Builds happen in isolated environment

**Implementation**: Add to GitHub Actions workflow

```yaml
# .github/workflows/cache.yml
name: Build and Cache

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:  # Manual trigger

jobs:
  cache:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: cachix/install-nix-action@v25
        with:
          nix_path: nixpkgs=channel:nixos-unstable

      - uses: cachix/cachix-action@v14
        with:
          name: lewisflude
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

      - name: Build and cache all outputs
        run: |
          nix build github:srid/devour-flake \
            -L --no-link --print-out-paths \
            --override-input flake . \
            | cachix push lewisflude
```

**Cost**: Uses GitHub Actions minutes, but saves significant time on future builds

---

### ? **Already Configured: System-Level Cachix**

**Where**: Cachix substituters are configured in `modules/shared/core.nix` for system builds.

**Current Setup**:

```nix
# modules/shared/core.nix
nix.settings = {
  substituters = [
    "https://lewisflude.cachix.org"
    # ... other caches
  ];
  trusted-public-keys = [
    "lewisflude.cachix.org-1:Y4J8FK/Rb7Es/PnsQxk2ZGPvSLup6ywITz8nimdVWXc="
    # ... other keys
  ];
};
```

**What it does**:

- Automatically pulls from cache during system builds (`nh os switch`, `darwin-rebuild switch`)
- Works for all Nix operations on configured systems
- No additional setup needed

**Note**: For flake-level operations (like `nix build`), you can optionally add `nixConfig` to `flake.nix`, but this requires `--accept-flake-config` flag or setting `accept-flake-config = true` in `nix.conf`. The current approach in `modules/shared/core.nix` works for all system builds without requiring flags.

---

### ?? **Not Recommended: Local System Rebuilds**

**When**: After `nh os switch` or `darwin-rebuild switch`

**Why NOT**:

- ? Adds significant time to rebuilds (5-30+ minutes)
- ? Users may not want to push everything
- ? Can expose local-only packages/configs
- ? Network dependency during rebuilds
- ? Cache storage costs

**Alternative**: Manual when needed

```bash
# After a rebuild, if you want to cache:
nix run .#setup-cachix push-all
```

---

### ? **Not Recommended: Git Hooks**

**When**: Pre-commit, post-commit, pre-push hooks

**Why NOT**:

- ? Would slow down every commit (unacceptable UX)
- ? Blocks commits if network is down
- ? Users may not have Cachix auth configured
- ? Can fail silently and confuse users

**Alternative**: Let CI handle it

---

### ?? **Maybe: On Flake Updates**

**When**: After `nix flake update` or `nix run .#update-all`

**Considerations**:

- ? Could cache new dependencies immediately
- ? Adds time to update process
- ? May cache things that won't be used

**Recommendation**: **Optional** - Better to let CI handle after merge

**If you want it** (optional script):

```bash
# Add to update-all script (optional)
after_update() {
  read -p "Cache updated packages? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    nix run .#setup-cachix push-all
  fi
}
```

---

## ?? Automation Matrix

| Scenario | Auto-Run? | Reason |
|----------|-----------|--------|
| **CI/CD (GitHub Actions)** | ? **Yes** | Fast CI, shared cache, isolated |
| **devenv builds** | ? **Yes** | Already configured, dev-only |
| **Local rebuilds** | ? **No** | Too slow, user control needed |
| **Git hooks** | ? **No** | Blocks commits, bad UX |
| **Flake updates** | ?? **Maybe** | Optional, better in CI |
| **Manual trigger** | ? **Always** | User-initiated, full control |

---

## ?? Recommended Setup

### 1. **CI Workflow** (Primary automation) ? **Already Created**

The workflow is already set up at `.github/workflows/ci.yml`. It includes:

- ? Checks and tests (flake check, pre-commit)
- ? Builds NixOS configurations
- ? Builds Darwin configurations (macOS)
- ? Caches all outputs using devour-flake (on main branch)
- ? Caches flake inputs

**To enable it**, just add the secret:

1. Go to: `https://github.com/lewisflude/nix-config/settings/secrets/actions`
2. Add secret: `CACHIX_AUTH_TOKEN` with your token from [Cachix](https://app.cachix.org/personal-auth-tokens)

The workflow will automatically:

- Run on every push/PR
- Cache builds on main branch
- Use devour-flake for efficient caching

### 2. **Keep devenv Auto-Push** ?

Your `devenv.nix` is already perfect:

```nix
{
  cachix.push = "lewisflude";
  cachix.pull = [ "lewisflude" ];
}
```

### 3. **Manual Commands Available**

For when you need them:

```bash
# Cache everything
nix run .#setup-cachix push-all

# Cache specific system
nix run .#setup-cachix push --system nixosConfigurations.jupiter

# Cache dev shells
nix run .#setup-cachix push-shells
```

---

## ?? Best Practices

1. **CI is primary**: Let GitHub Actions handle most caching
2. **devenv for dev**: Keep auto-push for development environments
3. **Manual for special cases**: Use `push-all` when you need it
4. **Monitor cache usage**: Check [Cachix dashboard](https://app.cachix.org/cache/lewisflude) regularly
5. **Don't block users**: Never auto-run on local rebuilds or git operations

---

## ?? Monitoring

**Check cache effectiveness**:

```bash
# View cache stats
nix run .#setup-cachix stats

# Or visit dashboard
open https://app.cachix.org/cache/lewisflude
```

**Key metrics to watch**:

- Cache hit rate (should be >80% after initial cache)
- Cache size (watch for bloat)
- Build time improvements (should see 10-30x speedup)

---

## ?? Summary

**Auto-run caching in**:

- ? CI/CD workflows (GitHub Actions)
- ? devenv environments (already configured)

**Don't auto-run in**:

- ? Local system rebuilds
- ? Git hooks
- ? Interactive commands

**Manual when needed**:

- `nix run .#setup-cachix push-all` - When you want to cache everything
- `nix run .#setup-cachix push --system <name>` - Cache specific system
