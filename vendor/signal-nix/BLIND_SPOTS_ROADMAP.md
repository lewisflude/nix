# Signal Theme Ecosystem: Blind Spots Remediation Roadmap

**Generated:** 2026-01-21  
**Priority:** Critical fixes first, then strategic expansion  
**Timeline:** Phased approach over 3-6 months

---

## Phase 1: Critical Fixes (Week 1-2) 🚨

**Goal:** Fix documentation accuracy and obvious missing pieces

### 1.1 Documentation Synchronization

**Tasks:**
- [ ] Create automated script to generate `theming-reference.md` from actual module files
- [ ] Update README.md application list to match reality
- [ ] Mark implementation depth: `🟢 Full`, `🟡 Colors Only`, `🔴 Missing`
- [ ] Add "last verified" dates to each application entry
- [ ] Create CHANGELOG entry for documentation fixes

**Files to update:**
- `README.md` - Fix app list
- `docs/theming-reference.md` - Regenerate from modules
- `scripts/generate-app-list.sh` (NEW) - Automation script

**Estimated time:** 8 hours

### 1.2 Add Actually Missing "Implemented" Apps

These are marked as implemented but module files don't exist:

**Critical Missing:**
- [ ] `modules/cli/lazydocker.nix` - Listed in README, no module

**Verification needed:**
- [ ] Check if "Foot" implementation is deep enough
- [ ] Verify "Fish" and "Nushell" color coverage
- [ ] Audit "Ranger", "LF", "NNN" file manager implementations

**Files to create/audit:**
- `modules/cli/lazydocker.nix`
- Review existing questionable modules

**Estimated time:** 12 hours

### 1.3 Quick Wins: Easy High-Impact Additions

**Low-hanging fruit (Tier 3 freeform settings):**
- [ ] **Micro** - Simple terminal editor (YAML config)
- [ ] **Rio** - Terminal emulator (TOML config)
- [ ] **Bemenu** - dmenu replacement (command-line options)
- [ ] **HTTPie** - API client (has config file)

**Why these:**
- Simple configuration formats
- High user demand
- Quick to implement (2-4 hours each)
- Complement existing coverage

**Estimated time:** 12 hours total

**Phase 1 Total:** ~32 hours (1 week full-time)

---

## Phase 2: GUI Application Foundation (Week 3-6) 🖥️

**Goal:** Theme the most visible desktop applications

### 2.1 GNOME Desktop Suite

**Priority apps (daily drivers for millions):**
- [ ] **Nautilus (Files)** - Most used Linux file manager
- [ ] **Evince** - Document viewer
- [ ] **Eye of GNOME** - Image viewer
- [ ] **GNOME Terminal** - Default GNOME terminal
- [ ] **GNOME Text Editor** - Replacing gedit
- [ ] **Geary** - Email client

**Implementation:**
- GTK themes via `modules/gtk/default.nix` extension
- Per-app CSS overrides where needed
- Use existing GTK3/4 foundation

**Estimated time:** 24 hours

### 2.2 KDE/Qt Desktop Suite

**Priority apps:**
- [ ] **Dolphin** - KDE file manager
- [ ] **Okular** - Document viewer
- [ ] **Gwenview** - Image viewer
- [ ] **Kate** - Text editor
- [ ] **Konsole** - KDE terminal
- [ ] **KMail** - Email client

**Implementation:**
- Audit/expand `modules/qt/default.nix`
- Qt stylesheet (QSS) generation
- Test with Qt5 and Qt6

**Estimated time:** 24 hours

### 2.3 Cross-Desktop GUI Apps

**Essential GUI apps:**
- [ ] **Thunderbird** - #1 Linux email client
- [ ] **VLC** - #1 media player
- [ ] **GIMP** - Image editing
- [ ] **Zathura** - PDF viewer (already mentioned in docs)

**Implementation:**
- Per-app theme files or CSS
- May need custom formats (VLC skins)

**Estimated time:** 16 hours

**Phase 2 Total:** ~64 hours (2 weeks full-time)

---

## Phase 3: Modern Developer Tools (Week 7-9) 💻

**Goal:** Support modern development workflows

### 3.1 AI & ML Tools

**High demand in 2024-2026:**
- [ ] **Ollama TUI** - Local LLM interface
- [ ] **aichat** - GPT CLI client
- [ ] **mods** - AI for command line
- [ ] **llm** - Simon Willison's LLM CLI

**Implementation:**
- Most use simple TOML/YAML configs
- Tier 3 freeform settings
- Color output configuration

**Estimated time:** 12 hours

### 3.2 Container & Kubernetes Ecosystem

**Critical for DevOps:**
- [ ] **k9s** - Kubernetes TUI (already mentioned)
- [ ] **dive** - Docker layer explorer
- [ ] **ctop** - Container metrics
- [ ] **lazydocker** - Docker TUI (Phase 1 if not done)

**Implementation:**
- YAML/TOML configurations
- TUI frameworks (tcell, bubble tea)

**Estimated time:** 16 hours

### 3.3 Cloud Provider CLIs

**Professional tooling:**
- [ ] **aws-cli** - AWS CLI colors
- [ ] **gcloud** - Google Cloud CLI colors
- [ ] **azure-cli** - Azure CLI colors
- [ ] **kubectl** - Kubernetes CLI (via kubecolor)

**Implementation:**
- Environment variables for colors
- Config file modifications
- Wrapper scripts where needed

**Estimated time:** 12 hours

### 3.4 API & Database Clients

**Developer daily drivers:**
- [ ] **HTTPie** - API testing (if not in Phase 1)
- [ ] **usql** - Universal SQL client
- [ ] **pgcli** - PostgreSQL client
- [ ] **mycli** - MySQL client

**Implementation:**
- Config files (~/.config/*)
- Syntax highlighting themes

**Estimated time:** 12 hours

**Phase 3 Total:** ~52 hours (1.5 weeks full-time)

---

## Phase 4: Media & Creative Apps (Week 10-11) 🎨

**Goal:** Theme creative and media consumption apps

### 4.1 Music Players & Audio

**Popular music apps:**
- [ ] **ncmpcpp** - MPD client TUI
- [ ] **cmus** - Terminal music player
- [ ] **Spotify-player** - TUI for Spotify
- [ ] **musikcube** - Modern terminal player

**Implementation:**
- Config file theming
- Color schemes

**Estimated time:** 12 hours

### 4.2 Visualization & Eye Candy

**System monitoring with style:**
- [ ] **Cava** - Audio visualizer
- [ ] **GLava** - OpenGL visualizer
- [ ] **Pipes.sh** - Animated pipes (can theme colors)

**Implementation:**
- Simple color configuration
- Shader/config files

**Estimated time:** 8 hours

### 4.3 Video Players

**Beyond MPV:**
- [ ] **VLC** - If not done in Phase 2
- [ ] **Celluloid** - GTK MPV frontend
- [ ] **SMPlayer** - Qt MPV frontend

**Implementation:**
- Qt/GTK themes
- VLC skin format

**Estimated time:** 8 hours

**Phase 4 Total:** ~28 hours (1 week full-time)

---

## Phase 5: Productivity & Communication (Week 12-13) 📧

**Goal:** Theme daily productivity applications

### 5.1 Email Clients

**Terminal email:**
- [ ] **Aerc** - Modern terminal email
- [ ] **NeoMutt** - Enhanced Mutt

**GUI email:**
- [ ] **Thunderbird** - If not done in Phase 2
- [ ] **Geary** - If not done in Phase 2

**Implementation:**
- Config file colors
- CSS for GUI apps

**Estimated time:** 12 hours

### 5.2 RSS & News Readers

**Content consumption:**
- [ ] **Newsboat** - RSS/Atom reader
- [ ] **newsraft** - Modern RSS reader
- [ ] **Glow** - Markdown viewer (verify current impl)

**Implementation:**
- Config files
- Color schemes

**Estimated time:** 8 hours

### 5.3 Task Management

**Getting things done:**
- [ ] **Taskwarrior-tui** - TUI for Taskwarrior
- [ ] **todo.txt-cli** - Plain text tasks
- [ ] **calcurse** - Calendar and tasks

**Implementation:**
- Config file theming
- Color schemes

**Estimated time:** 8 hours

**Phase 5 Total:** ~28 hours (1 week full-time)

---

## Phase 6: macOS-Specific Support (Week 14-15) 🍎

**Goal:** Proper nix-darwin support

### 6.1 macOS Terminal Emulators

**Critical for macOS users:**
- [ ] **iTerm2** - Most popular macOS terminal
- [ ] **Terminal.app** - System default (limited theming)
- [ ] **Warp** - Modern AI terminal

**Implementation:**
- iTerm2: dynamic profiles (plist)
- Terminal.app: .terminal files
- Warp: YAML config

**Estimated time:** 12 hours

### 6.2 macOS Launchers & Utilities

**macOS-specific tools:**
- [ ] **Alfred** - Popular launcher (workflows can use colors)
- [ ] **Raycast** - Modern launcher (extensions can theme)
- [ ] **yabai** - macOS window manager
- [ ] **skhd** - Hotkey daemon

**Implementation:**
- Config files
- May need per-app approaches

**Estimated time:** 12 hours

**Phase 6 Total:** ~24 hours (1 week full-time)

---

## Phase 7: Testing & Quality Assurance (Week 16-17) ✅

**Goal:** Ensure quality and prevent regressions

### 7.1 Visual Regression Testing

**Infrastructure:**
- [ ] Set up screenshot capture automation
- [ ] Create "golden master" screenshots for each app
- [ ] Implement pixel-diff comparison
- [ ] Add to CI/CD pipeline

**Tools to use:**
- Playwright/Puppeteer for GUI apps
- Terminal screenshot tools for TUI apps
- ImageMagick for comparison

**Estimated time:** 16 hours

### 7.2 Accessibility Testing

**APCA Verification:**
- [ ] Create contrast checker script
- [ ] Verify all text meets APCA standards
- [ ] Generate accessibility report
- [ ] Add color blindness simulation

**Tools:**
- APCA calculator implementation
- Color blindness simulation (Coblis, etc.)

**Estimated time:** 12 hours

### 7.3 Expand Integration Tests

**Test coverage:**
- [ ] Add tests for all Phase 2-6 applications
- [ ] Test light mode thoroughly
- [ ] Test autoEnable edge cases
- [ ] Add cross-platform tests (Linux/macOS)

**Estimated time:** 12 hours

**Phase 7 Total:** ~40 hours (1.5 weeks full-time)

---

## Phase 8: Documentation & Community (Week 18-19) 📚

**Goal:** Make Signal discoverable and usable

### 8.1 Visual Showcase

**Create:**
- [ ] Screenshot gallery website
- [ ] Video walkthrough (5-10 minutes)
- [ ] "Before/after" comparisons with other themes
- [ ] "Color science" explainer video

**Tools:**
- Static site generator (Astro, 11ty)
- OBS Studio for screen recording
- Figma for comparison graphics

**Estimated time:** 16 hours

### 8.2 Enhanced Documentation

**New docs:**
- [ ] "Why Signal?" visual guide with screenshots
- [ ] Per-application configuration guides (top 20 apps)
- [ ] Migration guides (from Catppuccin, Dracula, etc.)
- [ ] Troubleshooting with actual examples and screenshots

**Estimated time:** 12 hours

### 8.3 Community Building

**Initiatives:**
- [ ] Create Discord/Matrix server
- [ ] User showcase gallery (submit your setup)
- [ ] "Made with Signal" badge
- [ ] YouTube tutorial series (3-5 videos)

**Estimated time:** 12 hours

**Phase 8 Total:** ~40 hours (1.5 weeks full-time)

---

## Phase 9: Ecosystem Integration (Week 20) 🔗

**Goal:** Interoperability with other systems

### 9.1 Theme Format Exports

**New exports:**
- [ ] base16 format export
- [ ] base24 format export
- [ ] Alacritty `.yaml` theme file
- [ ] Kitty `.conf` theme file
- [ ] VSCode extension packaging
- [ ] JetBrains theme export

**Implementation:**
- Extend `generate-exports.js` in signal-palette
- Create new export formats

**Estimated time:** 12 hours

### 9.2 Framework Integration

**Integrate with:**
- [ ] Stylix - Popular Nix theming framework
- [ ] home-manager themes module
- [ ] nix-colors (if synergistic)

**Implementation:**
- Create Stylix adapter
- Contribute Signal to upstream frameworks

**Estimated time:** 8 hours

**Phase 9 Total:** ~20 hours (1 week full-time)

---

## Ongoing: Maintenance & Expansion (Week 21+) 🔄

**Continuous improvement:**

### Weekly Tasks

- [ ] Monitor new applications and trends
- [ ] Update existing modules for upstream changes
- [ ] Review and merge community contributions
- [ ] Update documentation as needed

### Monthly Tasks

- [ ] Run full test suite
- [ ] Update screenshot gallery
- [ ] Check for broken upstream links
- [ ] Audit module quality (depth vs breadth)

### Quarterly Tasks

- [ ] Major version bump (if needed)
- [ ] Reassess priorities based on user feedback
- [ ] Expand to new application categories
- [ ] Performance optimization pass

---

## Priority Matrix

| Phase | Priority | Impact | Effort | ROI |
|-------|----------|--------|--------|-----|
| **Phase 1: Critical Fixes** | 🔴 Critical | High | Low | ⭐⭐⭐⭐⭐ |
| **Phase 2: GUI Apps** | 🔴 Critical | Very High | Medium | ⭐⭐⭐⭐⭐ |
| **Phase 3: Dev Tools** | 🟡 High | High | Medium | ⭐⭐⭐⭐ |
| **Phase 4: Media** | 🟢 Medium | Medium | Low | ⭐⭐⭐ |
| **Phase 5: Productivity** | 🟡 High | High | Low | ⭐⭐⭐⭐ |
| **Phase 6: macOS** | 🟢 Medium | Medium | Medium | ⭐⭐⭐ |
| **Phase 7: Testing** | 🔴 Critical | Very High | High | ⭐⭐⭐⭐⭐ |
| **Phase 8: Docs** | 🟡 High | Very High | Medium | ⭐⭐⭐⭐⭐ |
| **Phase 9: Integration** | 🟢 Medium | Medium | Low | ⭐⭐⭐ |

---

## Resource Requirements

### Time Estimates

| Phase | Hours | Weeks (Full-time) |
|-------|-------|-------------------|
| Phase 1 | 32 | 1 week |
| Phase 2 | 64 | 2 weeks |
| Phase 3 | 52 | 1.5 weeks |
| Phase 4 | 28 | 1 week |
| Phase 5 | 28 | 1 week |
| Phase 6 | 24 | 1 week |
| Phase 7 | 40 | 1.5 weeks |
| Phase 8 | 40 | 1.5 weeks |
| Phase 9 | 20 | 1 week |
| **Total** | **328 hours** | **~11 weeks** |

**Note:** This is full-time estimate. For part-time (10 hrs/week), multiply by ~4x (40 weeks / 10 months).

### Skills Needed

- **Nix/NixOS expertise** - Module development
- **Color theory knowledge** - OKLCH, APCA
- **UI/UX design** - Visual showcase
- **Documentation writing** - Clear, accessible docs
- **Testing/QA** - Test infrastructure
- **Community management** - Discord, issue triage

---

## Success Metrics

### Quantitative Metrics

- [ ] **Documentation accuracy:** 0 conflicts between README and reality
- [ ] **Application coverage:** 100 apps (up from 64 claimed)
- [ ] **GUI app coverage:** 20+ GUI apps (currently ~3)
- [ ] **Test coverage:** 80% of modules have tests
- [ ] **Visual regression:** 0 color bugs in new releases

### Qualitative Metrics

- [ ] **User satisfaction:** Positive feedback on showcase/docs
- [ ] **Contribution rate:** 2+ community PRs per month
- [ ] **Discoverability:** 100+ GitHub stars (current unknown)
- [ ] **Adoption:** 5+ user showcases submitted

---

## Alternative Approaches

### Approach A: Depth over Breadth (Recommended)

**Focus:** Perfect 50 apps instead of mediocre 100 apps

**Benefits:**
- Higher quality user experience
- Easier to maintain
- Better reputation

**Drawbacks:**
- Lower app count for marketing
- Some users' apps not covered

### Approach B: Breadth first

**Focus:** Add 50+ apps quickly with minimal theming

**Benefits:**
- Impressive app count
- More users can try Signal

**Drawbacks:**
- Lower quality
- More maintenance burden
- Disappointing UX ("themed" but barely)

### Approach C: GUI-first

**Focus:** Nail all GUI apps, TUI apps are secondary

**Benefits:**
- Most visible impact
- Differentiation (other themes focus on TUI)
- Broader appeal (less technical users)

**Drawbacks:**
- Power users (target audience?) may prefer TUI focus
- GUI theming is harder (less standardized)

---

## Recommendations

### Immediate Next Steps (This Week)

1. **Fix documentation** - Run sync script, update README
2. **Add lazydocker** - It's listed but missing
3. **Create screenshot gallery** - Even just 10 screenshots
4. **Start Phase 2** - Nautilus and Dolphin are highest impact

### Strategic Direction

**Go with Approach A (Depth over Breadth):**
- Mark implementations as 🟢 Full, 🟡 Colors Only, 🔴 Missing
- Aim for 60-80 **truly comprehensive** implementations
- Focus on "daily driver" apps over niche tools

**Prioritize GUI applications:**
- File managers, email, document viewers are most visible
- Differentiate from other themes (most are TUI-focused)
- Broader appeal = more users = more contributors

**Build community early:**
- Create Discord server during Phase 1
- User showcase from day 1
- Make contributing easy and welcoming

---

## Risks & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Scope creep** | High | High | Stick to roadmap phases |
| **Maintainer burnout** | Critical | Medium | Get co-maintainers, automate |
| **App updates break themes** | High | High | CI/CD integration tests |
| **Community doesn't materialize** | Medium | Medium | Active promotion, showcases |
| **Qt/GTK theming too complex** | Medium | Low | Start simple, iterate |
| **macOS testing unavailable** | Medium | Low | Use GitHub Actions macOS runners |

---

## Conclusion

Signal has a **solid foundation** but needs focused effort on:

1. ✅ **Documentation accuracy** (Week 1)
2. ✅ **GUI application support** (Weeks 3-6)
3. ✅ **Modern tooling** (Weeks 7-9)
4. ✅ **Testing infrastructure** (Weeks 16-17)
5. ✅ **Visual showcase** (Weeks 18-19)

With this roadmap, Signal can go from **"impressive TUI theme"** to **"comprehensive Linux/macOS theme ecosystem"** in 3-6 months.

**Next action:** Start Phase 1 this week.

---

**Roadmap by:** Cursor AI  
**Date:** 2026-01-21  
**Based on:** BLIND_SPOTS_ANALYSIS.md  
**Timeline:** 3-6 months (full-time equivalent)
