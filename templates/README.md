# Module Templates

This directory contains templates for creating new Nix modules, overlays, and tests.

## Available Templates

### 1. Feature Module (`feature-module.nix`)

Use this template for creating new feature modules that integrate with the host configuration system.

**Use cases:**
- Adding support for new development tools (Docker, Kubernetes, etc.)
- Enabling optional system features (backup, monitoring, etc.)
- Platform-specific configurations

**How to use:**
```bash
./scripts/utils/new-module.sh feature <feature-name>
```

**Example:**
```bash
./scripts/utils/new-module.sh feature kubernetes
# Creates: modules/nixos/features/kubernetes.nix
```

**What it includes:**
- Options integration with `host.features.*`
- Platform detection (Linux/Darwin)
- Assertions for dependencies
- Home Manager integration
- Service configuration

### 2. Service Module (`service-module.nix`)

Use this template for standalone system services that don't fit into the feature system.

**Use cases:**
- Custom daemons and services
- Third-party applications with systemd services
- Self-hosted applications

**How to use:**
```bash
./scripts/utils/new-module.sh service <service-name>
```

**Example:**
```bash
./scripts/utils/new-module.sh service prometheus
# Creates: modules/nixos/services/prometheus.nix
```

**What it includes:**
- Service user and group creation
- Systemd service configuration
- Security hardening options
- Data directory management
- Firewall configuration

### 3. Overlay Template (`overlay-template.nix`)

Use this template for overriding or adding packages to nixpkgs.

**Use cases:**
- Overriding package versions
- Patching packages
- Adding custom packages
- Creating package wrappers

**How to use:**
```bash
./scripts/utils/new-module.sh overlay <overlay-name>
```

**Example:**
```bash
./scripts/utils/new-module.sh overlay custom-packages
# Creates: overlays/custom-packages.nix
```

**What it includes:**
- Package override examples
- Custom package definition
- Wrapper package example

### 4. Test Module (`test-module.nix`)

Use this template for creating NixOS VM tests.

**Use cases:**
- Testing feature modules
- Integration testing
- Regression testing
- CI/CD validation

**How to use:**
```bash
./scripts/utils/new-module.sh test <test-name>
```

**Example:**
```bash
./scripts/utils/new-module.sh test docker-feature
# Creates: tests/docker-feature.nix
```

**What it includes:**
- VM configuration
- Test script examples
- Service validation
- Integration testing patterns

## Manual Template Usage

If you prefer not to use the script, you can manually copy and customize templates:

1. **Copy the template:**
   ```bash
   cp templates/feature-module.nix modules/nixos/features/my-feature.nix
   ```

2. **Replace placeholders:**
   - `FEATURE_NAME` → Your feature name (snake_case)
   - `SERVICE_NAME` → Your service name (snake_case)
   - `DESCRIPTION` → Brief description
   - `CATEGORY` → Module category (shared/nixos/darwin)

3. **Update imports:**
   - Add your module to the appropriate `default.nix`
   - For features, add options to `modules/shared/host-options.nix`

4. **Test:**
   ```bash
   # Evaluate the configuration
   nix eval .#nixosConfigurations.<hostname>.config.system.build.toplevel
   
   # Build in VM for testing
   nix build .#nixosConfigurations.<hostname>.config.system.build.vm
   ./result/bin/run-*-vm
   ```

## Best Practices

### Feature Modules

1. **Always use conditionals:** Wrap all configuration in `mkIf cfg.enable`
2. **Add assertions:** Validate dependencies and requirements
3. **Platform detection:** Use `pkgs.stdenv.isLinux` and `pkgs.stdenv.isDarwin`
4. **Home Manager integration:** Configure user-level tools when appropriate
5. **Document options:** Add clear descriptions to all options

### Service Modules

1. **Security hardening:** Always enable systemd security features
2. **User isolation:** Create dedicated users for services
3. **Data directories:** Use `systemd.tmpfiles.rules` for directory creation
4. **Restart policies:** Configure appropriate restart behavior
5. **Logging:** Ensure services log to journald

### Overlays

1. **Minimal changes:** Only override what's necessary
2. **Version pinning:** Pin versions for stability
3. **Build inputs:** Document why additional inputs are needed
4. **Testing:** Test overlays in isolation before applying system-wide
5. **Meta information:** Include proper metadata for custom packages

### Test Modules

1. **Wait for services:** Use `wait_for_unit()` before testing
2. **Meaningful assertions:** Check actual functionality, not just existence
3. **Clean tests:** Each test should be independent
4. **Error messages:** Provide clear failure messages
5. **Performance:** Keep tests fast and focused

## Examples

### Creating a Docker Feature

```bash
# 1. Create the module
./scripts/utils/new-module.sh feature docker

# 2. Edit modules/shared/host-options.nix
# Add:
#   docker = {
#     enable = mkEnableOption "Docker container runtime";
#     rootless = mkOption {
#       type = types.bool;
#       default = false;
#       description = "Run Docker in rootless mode";
#     };
#   };

# 3. Implement in modules/nixos/features/docker.nix
# (customize the generated template)

# 4. Enable in host config
# host.features.docker.enable = true;
```

### Creating a Custom Service

```bash
# 1. Create the module
./scripts/utils/new-module.sh service my-app

# 2. Customize modules/nixos/services/my-app.nix

# 3. Enable in configuration.nix
# services.my-app = {
#   enable = true;
#   port = 3000;
# };
```

## Template Maintenance

When updating templates:

1. Update the template file in `templates/`
2. Update this README with any new features
3. Test template generation with the script
4. Document breaking changes in the changelog

## Questions?

- See existing modules for real-world examples
- Check `docs/ARCHITECTURE.md` for design patterns
- Ask in GitHub discussions

---

**Note:** These templates follow the conventions established in this Nix configuration. Adjust them to match your specific needs and coding style.
