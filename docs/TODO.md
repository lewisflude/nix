# TODO: Future Refactoring Tasks

This document tracks potential refactorings and improvements identified during code audits.

## High Priority

### 1. Simplify SOPS Secret Permissions

**Location:** `modules/nixos/system/sops.nix:29-31`

**Current Issue:**

```nix
sops.secrets =
  lib.genAttrs sharedSecrets (_: {
    owner = lib.mkForce "root";
    group = lib.mkForce "sops-secrets";
    mode = lib.mkForce "0440";
  })
```

Using `mkForce` on every secret to override default permissions is heavy-handed.

**Proposed Solution:**

- Investigate why `mkForce` is needed - check if `modules/shared/sops.nix` has conflicting defaults
- If shared module uses `mkDefault`, we shouldn't need `mkForce`
- Consider using `sops.defaultSecretOptions` at NixOS level instead of per-secret overrides
- Verify if the "neededForUsers" comment/issue can be solved differently

**Benefits:**

- Cleaner configuration
- More maintainable secret management
- Better interaction with SOPS module defaults

---

### 2. Make Gaming-Aware Sysctl Configuration

**Location:** `modules/nixos/features/gaming.nix:29`

**Current Issue:**

```nix
boot.kernel.sysctl = {
  # Must override disk-performance.nix's conservative value (262144)
  "vm.max_map_count" = lib.mkForce 2147483642;
};
```

Gaming module needs to override disk-performance module's value, creating a module priority conflict.

**Proposed Solution:**

**Option A: Make disk-performance gaming-aware**

```nix
# In modules/nixos/performance/disk-performance.nix
boot.kernel.sysctl."vm.max_map_count" = lib.mkDefault (
  if config.host.features.gaming.enable
  then 2147483642  # Gaming workload
  else 262144      # Conservative default
);
```

**Option B: Use priority-based approach**

```nix
# In lib/sysctl-defaults.nix
defaults = {
  vm.max_map_count = {
    base = 262144;
    gaming = 2147483642;
  };
};

# In disk-performance.nix
boot.kernel.sysctl."vm.max_map_count" = lib.mkDefault sysctl.vm.max_map_count.base;

# In gaming.nix
boot.kernel.sysctl."vm.max_map_count" = lib.mkOverride 60 sysctl.vm.max_map_count.gaming;
```

**Benefits:**

- Removes `mkForce` hack
- Makes module interactions explicit
- Easier to reason about configuration precedence

---

### 3. Extract Delayed Boot Pattern into Reusable Module

**Location:** `hosts/jupiter/configuration.nix:136-163`

**Current Issue:**

```nix
systemd.services = {
  ollama.wantedBy = lib.mkForce [ ];
  open-webui.wantedBy = lib.mkForce [ ];

  delayed-services = {
    # Custom timer implementation...
  };
};
```

Host-specific workaround for faster boot times by delaying non-essential services.

**Proposed Solution:**

Create `modules/nixos/features/boot-optimization.nix`:

```nix
{
  options.host.features.bootOptimization = {
    enable = lib.mkEnableOption "boot optimization with delayed services";

    delayedServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Services to delay starting until after boot completes";
      example = [ "ollama" "open-webui" ];
    };

    delaySeconds = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Seconds to wait after boot before starting delayed services";
    };
  };

  config = lib.mkIf cfg.enable {
    # Generic implementation of delayed service pattern
  };
}
```

**Benefits:**

- Reusable across any host
- No more per-host mkForce hacks
- Clear opt-in mechanism for boot optimization
- Could benefit other hosts (mercury, saturn, etc.)

---

## Medium Priority

### 4. Upstream Sonarr Data Path Fix

**Location:** `modules/nixos/services/media-management/sonarr.nix:38`

**Current Issue:**

```nix
serviceConfig.ExecStart = lib.mkForce "${config.services.sonarr.package}/bin/Sonarr -nobrowser -data=/var/lib/sonarr/.config/Sonarr";
```

Overriding NixOS module's ExecStart to use modern Sonarr directory instead of legacy NzbDrone path.

**Proposed Solutions:**

**Option A: Upstream to nixpkgs**

- Submit PR to add `services.sonarr.dataPath` option
- Or update default path to use modern `.config/Sonarr` instead of `.config/NzbDrone`

**Option B: Local module overlay**

```nix
# In overlays/sonarr-fix.nix
{ config, lib, ... }:
{
  # Properly override the module instead of using mkForce
}
```

**Option C: Check if fixed in newer nixpkgs**

- Verify if nixpkgs 24.11 or unstable has fixed this
- Remove override if upstream is fixed

**Benefits:**

- Removes maintenance burden
- Helps entire Nix community
- Proper upstream solution vs local hack

---

### 5. Document or Fix Desktop Session Management

**Location:** `modules/nixos/features/desktop/desktop-environment.nix:38`

**Current Issue:**

```nix
# Disable the plain niri session, only use UWSM-managed session
services.displayManager.sessionPackages = lib.mkForce [ ];
```

Clearing default session packages to exclusively use UWSM-managed sessions.

**Proposed Solutions:**

**Option A: Check upstream niri options**

- Verify if `programs.niri` has option to disable auto-session registration
- If exists, use proper option instead of mkForce

**Option B: Document reasoning**

```nix
# UWSM (Universal Wayland Session Manager) requires exclusive session control.
# Niri's default session registration conflicts with UWSM's session management,
# causing duplicate session entries and potential startup issues.
# We use mkForce to ensure only UWSM-managed sessions are registered.
services.displayManager.sessionPackages = lib.mkForce [ ];
```

**Option C: Upstream feature request**

- Open issue in nixpkgs for `programs.niri.registerSession = mkDefault true;`
- Would allow downstream to opt-out without mkForce

**Benefits:**

- Better code documentation
- Potentially upstreamable improvement
- Clearer intent for future maintainers

---

### 6. Consolidate Test VM Configuration

**Locations:**

- `tests/default.nix:20,33`
- `tests/integration/mcp.nix:46`

**Current Issue:**

```nix
# Repeated in multiple test files
boot.loader.systemd-boot.enable = lib.mkForce false;
services.xserver.enable = lib.mkForce false;
```

Tests need to disable features that imported modules enable.

**Proposed Solution:**

Create `tests/lib/vm-base.nix`:

```nix
{ lib, ... }:
{
  # Common VM test configuration
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  # Minimal VM setup
  services.xserver.enable = lib.mkForce false;
  virtualisation.graphics = false;

  fileSystems."/" = {
    device = "/dev/vda";
    fsType = "ext4";
  };
}
```

Update `mkTestMachine` helper:

```nix
mkTestMachine =
  hostFeatures:
  { ... }:
  {
    imports = [
      ./lib/vm-base.nix  # Common test overrides
      ../modules/shared
      ../modules/nixos
    ];

    config.host = {
      username = "testuser";
      features = hostFeatures;
    };
  };
```

**Benefits:**

- DRY principle - define overrides once
- Consistent test environment
- Easier to maintain test infrastructure

---

## Low Priority (Already Justified)

### 7. Darwin Nix Daemon Management

**Location:** `modules/darwin/nix.nix:164`

```nix
nix = {
  # Determinate Nix owns the daemon + /etc/nix/nix.conf; keep nix-darwin out
  enable = lib.mkForce false;
};
```

**Status:** ✅ **No action needed**

This is the correct use of `mkForce`. Determinate Nix installation requires disabling nix-darwin's daemon management. Well-documented and justified.

---

## Additional Potential Improvements

### Future Considerations

- **Audit other `mkOverride` usage** - Similar patterns might exist
- **Create module interaction documentation** - Document which modules intentionally override each other
- **Establish priority guidelines** - When to use mkDefault/mkForce/mkOverride
- **Module dependency graph** - Use `nix run .#visualize-modules` to identify interaction patterns

---

## Contributing

When working on these TODOs:

1. **Read existing code** - Understand why mkForce was used originally
2. **Test thoroughly** - Ensure refactoring doesn't break functionality
3. **Update this document** - Mark completed items, add new findings
4. **Follow conventions** - See `docs/CONVENTIONS.md` and `docs/DX_GUIDE.md`
5. **Consider upstreaming** - Some fixes benefit the entire Nix community

---

## Completed Items

*None yet - mark items with ~~strikethrough~~ and move here when completed*
