# Hytale Server Module - Final Extraction Plan

## Executive Summary

After deeper research and analysis, **extraction is recommended with important caveats and a phased approach.**

---

## Critical Findings from Research

### ✅ Confirmed: Hytale is Available
- Flatpak launcher installed and available on Flathub
- Official server documentation exists
- OAuth authentication infrastructure is live
- Server hosting is production-ready

### ⚠️ CRITICAL: Implementation is Brand New
- **Added only 6 days ago** (January 16, 2026)
- **Not yet committed** to git main
- **Zero production validation** - hasn't been tested in real deployment
- Module may have undiscovered bugs or issues

### ❌ hytale-downloader.nix is Non-Functional
```nix
url = "https://example.com/hytale-downloader.zip"; # PLACEHOLDER
hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # PLACEHOLDER
```
- 100% placeholder code
- Will not build
- Should NOT be included in extraction

### ⚠️ Java 25 Not Yet in Nixpkgs
- Has good fallback mechanism (falls back to latest JDK with warning)
- Not a blocker, but worth noting
- Community users will see warning messages initially

---

## Revised Recommendation: Phased Approach

### ❌ DO NOT Extract Immediately

**Why not:**
1. Module is untested in production (6 days old)
2. Likely to have bugs that need fixing
3. No real-world validation yet
4. Premature release could damage reputation

### ✅ INSTEAD: Two-Phase Strategy

---

## Phase 1: Preparation & Validation (Next 2-4 Weeks)

### Week 1-2: Production Validation
**Goal**: Prove the module works in real deployment

**Actions**:
1. **Commit current implementation** to git main
   - Get it into your production config
   - This is Jupiter host, which will actually use it

2. **Deploy to Jupiter** (if not already deployed)
   ```bash
   # User runs:
   nh os switch
   ```

3. **Monitor for issues**:
   - Service stability
   - File detection (Flatpak auto-detection)
   - Authentication flow
   - Backup functionality
   - Resource usage
   - Log for errors: `journalctl -u hytale-server -f`

4. **Test edge cases**:
   - Symlink vs copy modes
   - Manual file paths
   - Firewall configuration
   - Memory tuning
   - Server restarts

5. **Document any issues** and fix them
   - Update module as needed
   - Refine documentation based on experience
   - Add troubleshooting based on real problems

**Success Criteria**:
- [ ] Service runs stably for 2+ weeks
- [ ] No critical bugs discovered
- [ ] Authentication works reliably
- [ ] Backups function correctly
- [ ] Performance is acceptable

### Week 2-4: Prepare Extraction Materials

**While validating, prepare extraction in parallel**:

1. **Create extraction structure** (in separate branch or private repo):
   ```
   hytale-server-nix/
   ├── flake.nix
   ├── module.nix              # Simplified service module
   ├── overlay.nix             # Java 25 overlay
   ├── README.md
   ├── LICENSE
   ├── CHANGELOG.md
   ├── .gitignore
   └── examples/
       ├── basic.nix
       ├── advanced.nix
       └── flake-usage.nix
   ```

2. **Simplify module.nix**:
   - Remove `lib/constants.nix` dependency → inline port 5520
   - Remove feature flag system
   - Keep only `services.hytaleServer` interface
   - Inline Java 25 overlay or include as separate file
   - Keep ALL functionality (Flatpak, backups, security, etc.)

3. **Migrate documentation**:
   - Convert `docs/HYTALE_SERVER.md` → `README.md`
   - Update examples to use standalone module syntax
   - Remove repository-specific patterns
   - Add flake input instructions
   - Include disclaimer (not affiliated)

4. **Create comprehensive examples**:
   - Basic: Minimal config with auto-detection
   - Advanced: All options with backups
   - Flake usage: How to import in user configs

5. **Write CHANGELOG.md**:
   ```markdown
   # Changelog
   
   ## [Unreleased]
   
   ## [0.1.0] - 2026-XX-XX
   ### Added
   - Initial release
   - NixOS module for Hytale game servers
   - Automatic Flatpak detection
   - Backup support
   - Security hardening
   - Comprehensive documentation
   
   ### Known Issues
   - Java 25 not yet in nixpkgs (falls back to latest JDK)
   ```

**Deliverables**:
- [ ] Extraction structure complete
- [ ] Documentation migrated and refined
- [ ] Examples functional
- [ ] Module simplified and tested locally

---

## Phase 2: Public Release (After Validation)

### Timing: 2-4 Weeks from Now

**Only proceed if**:
- [x] Module has been production-tested
- [x] No critical bugs remain
- [x] You're confident in the implementation
- [x] Ready to support community users

### Release Steps

#### 1. Create Public Repository

**Repository name**: `hytale-server-nix`

**Initialize**:
```bash
# Create repo on GitHub
gh repo create hytale-server-nix --public --description "NixOS module for Hytale game servers"

# Push prepared content
cd /path/to/prepared/extraction
git init
git add .
git commit -m "Initial release v0.1.0"
git remote add origin git@github.com:username/hytale-server-nix.git
git push -u origin main
```

#### 2. Version as 0.1.0 (Beta Signal)

**Why 0.x versioning:**
- Signals "early stage" to users
- Sets expectation of potential changes
- Allows flexibility for breaking changes
- Semantic: 0.1.0 → 0.2.0 → ... → 1.0.0 (stable)

**Tag release**:
```bash
git tag -a v0.1.0 -m "Initial beta release

First public release of the Hytale server module.

Features:
- Automatic Flatpak detection
- Systemd service management
- Security hardening
- Backup support
- Comprehensive documentation

Known Issues:
- Java 25 not yet in nixpkgs (uses fallback)
- Beta software - expect changes"

git push origin v0.1.0
```

#### 3. Create GitHub Release

**Title**: `v0.1.0 - Initial Beta Release`

**Description**:
```markdown
# 🎮 Hytale Server for NixOS - Beta Release

First public release of the NixOS module for hosting Hytale game servers.

## ⚠️ Beta Software

This is an early beta release. The module is functional but may have rough edges. 
Feedback and contributions are welcome!

## ✨ Features

- **Declarative Configuration** - Manage servers with Nix
- **Automatic Flatpak Integration** - Auto-detects Hytale installation
- **Security Hardening** - Systemd hardening and resource limits
- **Backup Support** - Automatic world backups
- **Comprehensive Docs** - Full setup and troubleshooting guide

## 🚀 Quick Start

See [README.md](README.md) for detailed instructions.

```nix
{
  inputs.hytale-server.url = "github:username/hytale-server-nix";
  
  outputs = { nixpkgs, hytale-server, ... }: {
    nixosConfigurations.myserver = nixpkgs.lib.nixosSystem {
      modules = [
        hytale-server.nixosModules.default
        {
          services.hytaleServer = {
            enable = true;
            memory = { max = "8G"; min = "4G"; };
          };
        }
      ];
    };
  };
}
```

## 📋 Known Issues

- Java 25 not yet in nixpkgs (module falls back to latest JDK with warning)
- Early testing phase - please report issues!

## 🤝 Contributing

Contributions welcome! See [README.md](README.md) for guidelines.

---

**Disclaimer**: Not affiliated with or endorsed by Hypixel Studios.
```

#### 4. Update Personal Config

**Add flake input** (`flake.nix`):
```nix
{
  inputs = {
    # ... existing inputs ...
    hytale-server.url = "github:username/hytale-server-nix";
  };
}
```

**Refactor feature module** to thin wrapper:
- Keep `modules/shared/host-options/features/hytale-server.nix` (API)
- Simplify `modules/nixos/features/hytale-server.nix` to bridge
- Remove `modules/nixos/services/hytale-server/` (now from flake)

**Test integration**:
```bash
nix flake lock --update-input hytale-server
nix flake check
nixos-rebuild dry-build --flake .#jupiter
# If successful, user rebuilds: nh os switch
```

#### 5. Announce to Community

**Timing**: Only after confirming module works in personal config + flake integration

**Target Venues**:

1. **NixOS Discourse** (Primary)
   - Category: Gaming
   - Title: `[Release] hytale-server-nix v0.1.0 - Host Hytale servers with NixOS`
   - Content:
     ```markdown
     I've created a NixOS module for hosting Hytale game servers: 
     https://github.com/username/hytale-server-nix
     
     Features:
     - Declarative configuration
     - Automatic Flatpak integration
     - Security hardening
     - Backup support
     
     This is a beta release - feedback welcome!
     
     [Include quick start example]
     ```

2. **r/NixOS** (Secondary)
   - Similar post to Discourse
   - Emphasize gaming/server use case

3. **Hytale Communities** (Optional, after validation)
   - r/Hytale
   - Hytale Discord (if server hosting channels exist)
   - Focus: "NixOS users can now easily host servers"

**Social Media** (Optional):
- Twitter/Mastodon: Brief announcement with link
- Tags: #NixOS #Hytale #GameServers

#### 6. Prepare for Support

**Set Expectations**:
- Add "Beta" badge to README
- Document known limitations clearly
- Provide issue template
- Set response time expectations

**Be Ready to**:
- Answer questions promptly (especially first week)
- Fix bugs quickly
- Accept PRs gracefully
- Update documentation based on feedback

---

## What to EXCLUDE from Extraction

### 1. ❌ hytale-downloader.nix

**Reason**: 100% non-functional placeholder

**Instead**:
- Exclude entirely from initial release
- Add note in README under "Future Plans":
  ```markdown
  ## Future Plans
  
  - [ ] Automated downloader integration (when official tool is available)
  - [ ] Multiple server instance support
  - [ ] Monitoring integration (Prometheus)
  ```

**If users ask**: "The module uses Flatpak auto-detection which is more reliable for now"

### 2. ❌ Client Launcher (home/nixos/apps/hytale.nix)

**Reason**: Different target audience

**Server vs Client**:
- **Server module**: For hosting game servers (target: server admins)
- **Client launcher**: For playing the game (target: gamers)

**Decision**: Keep server module focused. Client launcher stays in personal config.

**Future**: Could be separate package/flake if demand exists

### 3. ❌ Repository-Specific Patterns

**Remove**:
- Feature flag system (`host.features.hytaleServer`)
- Constants.nix dependency
- Host options abstraction layer

**Keep**:
- Direct `services.hytaleServer` interface
- All actual functionality
- Self-contained module

---

## What to INCLUDE in Extraction

### ✅ Core Service Module

**Full functionality**:
- Systemd service configuration
- Flatpak auto-detection (symlink or copy)
- File validation
- Security hardening
- Resource limits
- Backup support
- Firewall configuration
- User/group management
- Activation scripts

**Simplified interface**:
```nix
services.hytaleServer = {
  enable = true;
  port = 5520;  # Inline default
  authMode = "authenticated";
  memory = { max = "8G"; min = "4G"; };
  # ... all other options
};
```

### ✅ Java 25 Overlay

**Options**:

**Option A**: Include in module.nix directly
```nix
# In module.nix config section
nixpkgs.overlays = [
  (final: prev: {
    jdk25 = if prev ? jdk25 then prev.jdk25 
            else builtins.trace "WARNING: Java 25 not found..." prev.jdk;
  })
];
```

**Option B**: Separate overlay.nix file
```nix
# overlay.nix
final: prev: {
  jdk25 = 
    if prev ? temurin_25_jdk then prev.temurin_25_jdk
    else if prev ? jdk25 then prev.jdk25
    else builtins.trace "WARNING: ..." prev.jdk;
}
```

**Recommendation**: Option B (cleaner, users can opt out)

### ✅ Comprehensive Documentation

**README.md sections**:
1. **Header**
   - Project description
   - Badges (optional)
   - Disclaimer (not affiliated)

2. **Quick Start**
   - Flake input
   - Minimal configuration
   - Deploy instructions

3. **Installation**
   - Detailed flake usage
   - Traditional NixOS configuration
   - Flatpak installation instructions

4. **Configuration**
   - All options documented
   - Examples for common scenarios
   - Memory recommendations table

5. **Flatpak Integration**
   - Auto-detection explanation
   - Symlink vs copy modes
   - Manual override instructions

6. **Authentication**
   - OAuth flow explanation
   - First-run instructions
   - Offline mode (testing only)

7. **Network Configuration**
   - QUIC/UDP explanation
   - Firewall setup
   - Port forwarding guide

8. **Troubleshooting**
   - Service won't start
   - Authentication issues
   - Connection problems
   - Performance tuning

9. **Architecture**
   - Module structure
   - Security hardening details
   - File management approach

10. **Contributing**
    - How to report issues
    - Pull request guidelines
    - Development setup

11. **License & Credits**
    - MIT license
    - Disclaimer
    - Links to official Hytale resources

### ✅ Example Configurations

**examples/basic.nix**:
```nix
{ config, ... }:

{
  # Minimal Hytale server with auto-detection
  services.hytaleServer = {
    enable = true;
    memory = {
      max = "4G";
      min = "2G";
    };
  };
}
```

**examples/advanced.nix**:
```nix
{ config, ... }:

{
  # Production Hytale server with all features
  services.hytaleServer = {
    enable = true;
    port = 5520;
    authMode = "authenticated";
    
    memory = {
      max = "16G";
      min = "8G";
    };
    
    backup = {
      enable = true;
      frequency = 30; # Every 30 minutes
      directory = "/var/backups/hytale";
    };
    
    jvmArgs = [
      "-XX:AOTCache=/var/lib/hytale-server/HytaleServer.aot"
      "-Xmx16G"
      "-Xms8G"
      "-XX:+UseG1GC"
      "-XX:MaxGCPauseMillis=200"
    ];
    
    serverFiles = {
      symlinkFromFlatpak = false; # Copy for stability
    };
  };
}
```

**examples/flake-usage.nix**:
```nix
{
  description = "My Hytale server configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hytale-server.url = "github:username/hytale-server-nix";
  };

  outputs = { self, nixpkgs, hytale-server }: {
    nixosConfigurations.gameserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        hytale-server.nixosModules.default
        {
          services.hytaleServer = {
            enable = true;
            memory = { max = "8G"; min = "4G"; };
          };
        }
      ];
    };
  };
}
```

---

## Success Metrics

### Phase 1 Success (Validation Period)
- [ ] Service runs stably for 2+ weeks on Jupiter
- [ ] No critical bugs discovered
- [ ] Authentication flow works reliably
- [ ] Backups function correctly
- [ ] Performance acceptable
- [ ] Documentation refined based on real use

### Phase 2 Success (Post-Release)

**Short-term (1 month)**:
- [ ] 5+ GitHub stars
- [ ] At least 1 community deployment reported
- [ ] No critical bugs in production
- [ ] Positive community feedback

**Medium-term (3 months)**:
- [ ] 25+ GitHub stars
- [ ] 3+ community contributions (issues/PRs)
- [ ] Multiple successful deployments
- [ ] Feature requests from users (indicates engagement)

**Long-term (6 months)**:
- [ ] 50+ GitHub stars
- [ ] Active community (regular issues/PRs)
- [ ] Consider v1.0.0 stable release
- [ ] Evaluate nixpkgs upstreaming

---

## Risk Mitigation

### Risk: Module Has Critical Bugs

**Probability**: Medium (untested in production)

**Mitigation**:
- Phase 1 validation period (2-4 weeks)
- Beta versioning (0.1.0) sets expectations
- Quick response to bug reports
- Can push fixes and update tag

### Risk: Low Community Adoption

**Probability**: Medium (new game, niche audience)

**Mitigation**:
- Low maintenance burden (declarative)
- Good documentation reduces friction
- First-mover advantage
- No pressure if adoption is slow

### Risk: Hytale Updates Break Module

**Probability**: Low-Medium (game is new)

**Mitigation**:
- Semantic versioning
- Changelog for updates
- Pin to stable releases in personal config
- Monitor Hytale release notes

### Risk: Java 25 Confusion

**Probability**: High (not in nixpkgs yet)

**Mitigation**:
- Clear warning message in module
- Document in README prominently
- Fallback works automatically
- Note it's temporary until nixpkgs updates

---

## Timeline

### Weeks 1-2: Validation
- Commit to git main
- Deploy to Jupiter
- Monitor for issues
- Fix any bugs discovered

### Weeks 2-3: Preparation
- Create extraction structure
- Simplify module
- Migrate documentation
- Create examples
- Test extraction locally

### Week 4: Integration Testing
- Add flake input to personal config
- Test thin wrapper approach
- Verify functionality preserved
- Final refinements

### Week 4-5: Release Decision
- Review validation results
- Decide if ready for public release
- If yes → proceed with Phase 2
- If no → continue validation, fix issues

### Post-Release: Support
- Announce in communities
- Monitor issues/questions
- Quick bug fixes
- Regular check-ins

---

## Alternative: Wait Longer

If after 4 weeks you're not confident:

**Option**: Delay public release
- Continue using in personal config
- Accumulate more production experience
- Wait for Java 25 in nixpkgs
- Wait for Hytale to mature
- Extract when truly ready

**No pressure to release early** - better to release quality software late than buggy software early.

---

## Checklist for Release Readiness

Before proceeding with Phase 2 (public release), confirm:

- [ ] Module has run stably in production for 2+ weeks
- [ ] No critical bugs remain
- [ ] Documentation is comprehensive and accurate
- [ ] Examples are tested and functional
- [ ] You're prepared to support community users
- [ ] Personal config successfully consumes flake
- [ ] Java 25 fallback is acceptable (or Java 25 is available)
- [ ] Comfortable with public visibility

**If any checkboxes are unchecked**: Delay release and continue validation.

---

## Final Recommendation

### ✅ YES to Extraction - BUT Use Phased Approach

**Phase 1 (Now)**: 
- Validate in production (2-4 weeks)
- Prepare extraction materials in parallel
- Fix any issues discovered

**Phase 2 (After Validation)**:
- Public release as v0.1.0 (beta)
- Community announcement
- Support and iterate

**Exclude**:
- hytale-downloader.nix (non-functional)
- Client launcher (different use case)
- Repository-specific patterns

**Include**:
- Core service module (simplified)
- Java 25 overlay
- Comprehensive documentation
- Example configurations

### Why This Approach is Best

1. **Prudent**: Validates before public release
2. **Prepared**: Extraction ready when validated
3. **Flexible**: Can adjust timeline based on validation
4. **Quality**: Ensures community gets stable software
5. **Safe**: 0.x versioning sets appropriate expectations

### Next Immediate Steps

1. **Commit current implementation** to git main
2. **Deploy to Jupiter** and monitor
3. **Start preparing extraction** in parallel
4. **Revisit decision in 2-4 weeks**

---

## Conclusion

The Hytale server module is a valuable contribution to the NixOS community, but its **extreme recency (6 days old)** warrants caution. 

**Use the two-phase approach**:
- Validate thoroughly first (you don't want to release buggy software)
- Prepare extraction in parallel (work is done, ready to go)
- Release when confident (2-4 weeks with production validation)

This balances first-mover advantage with quality assurance.

**The module will be valuable to the community - just make sure it's ready first.**
