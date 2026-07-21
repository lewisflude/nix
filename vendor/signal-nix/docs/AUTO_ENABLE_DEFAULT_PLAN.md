# Technical Plan: Make `theming.signal.enable = true` Enable All Modules by Default

**Goal**: Change `autoEnable` default from `false` to `true` so that `theming.signal.enable = true` automatically themes all enabled programs without requiring an additional `autoEnable = true` setting.

**Status**: ✅ COMPLETED (2026-01-21)
**Breaking Change**: Yes (Minor)
**Estimated Impact**: Low-Medium
**Commits**:
- `5b6718a` - feat: make autoEnable default to true for zero-config theming
- `e835c42` - style: remove trailing whitespace from documentation files

---

## ✅ Implementation Summary

All phases completed successfully:
- ✅ Phase 1: Core module changes (2 files)
- ✅ Phase 2: Documentation updates (7 files)
- ✅ Phase 3: Example files (8 files, 2 new)
- ✅ Phase 4: Test suite updates (1 file)
- ✅ Phase 5: Quality assurance
- ✅ Phase 6: CHANGELOG and release notes

**Result**: `theming.signal.enable = true` now automatically themes all enabled programs by default!

---

---

## Current Behavior

```nix
theming.signal = {
  enable = true;  # ← Only enables Signal infrastructure
  # autoEnable defaults to false
};
# Result: NO programs are themed

# To actually theme programs, users must either:
# Option 1: Set autoEnable
theming.signal = {
  enable = true;
  autoEnable = true;  # ← Required to theme programs
};

# Option 2: Explicitly enable each app
theming.signal = {
  enable = true;
  editors.helix.enable = true;
  terminals.kitty.enable = true;
  # ... etc for every app
};
```

## Proposed Behavior

```nix
theming.signal = {
  enable = true;  # ← Automatically themes all enabled programs
};
# Result: ALL enabled programs are themed

# Users can opt-out for specific programs:
theming.signal = {
  enable = true;
  cli.bat.enable = false;  # ← Explicitly disable specific apps
};

# Or disable autoEnable entirely (rare):
theming.signal = {
  enable = true;
  autoEnable = false;  # ← Opt-out of auto-theming
  editors.helix.enable = true;  # ← Manual per-app control
};
```

---

## Implementation Changes

### 1. Core Module Changes (Required)

#### A. Home Manager Module
**File**: `modules/common/default.nix`
**Change**: Line 120

```diff
     autoEnable = mkOption {
       type = types.bool;
-      default = false;
+      default = true;
       description = ''
         Automatically enable Signal theming for all programs/services
         that are already enabled in your configuration.

         When enabled, Signal will detect if a program is enabled
         (e.g., programs.helix.enable = true) and automatically apply
         Signal colors to it.

-        You can still explicitly enable/disable theming for specific
+        You can still explicitly disable theming for specific
         programs using the per-application enable options.
       '';
     };
```

#### B. NixOS Module
**File**: `modules/nixos/common/default.nix`
**Change**: Line 38

```diff
     autoEnable = mkOption {
       type = types.bool;
-      default = false;
+      default = true;
       description = ''
         Automatically enable Signal theming for all system components
         that are already enabled in your NixOS configuration.

         When enabled, Signal will detect if a system service is enabled
         (e.g., services.xserver.displayManager.gdm.enable = true) and
         automatically apply Signal colors to it.

-        You can still explicitly enable/disable theming for specific
+        You can still explicitly disable theming for specific
         components using the per-component enable options.
       '';
     };
```

---

## Documentation Updates

### 2. User-Facing Documentation

#### A. README.md
**File**: `README.md`
**Changes**:
- Update "Quick Start" section to emphasize simplicity
- Remove `autoEnable = true;` from basic examples (now implicit)
- Add note that `autoEnable` defaults to `true`
- Show opt-out pattern for disabling specific apps

**Before**:
```nix
theming.signal = {
  enable = true;
  autoEnable = true;  # ← Required
  mode = "dark";
};
```

**After**:
```nix
theming.signal = {
  enable = true;  # ← That's it! Auto-theming is now default
  mode = "dark";
};
```

#### B. Getting Started Guide
**File**: `docs/getting-started.md`
**Changes**:
- Simplify "Quick Start" example
- Move `autoEnable = false` pattern to "Advanced Usage" section
- Emphasize that Signal "just works" by default
- Update flowchart to show new default path

#### C. Configuration Guide
**File**: `docs/configuration-guide.md`
**Section**: "Activation Patterns"
**Changes**:
- Reorder sections: "Automatic Theming" (default) before "Selective Theming"
- Rename "Automatic Theming" to "Default Behavior (Auto-Enable)"
- Add "Selective Theming (Opt-Out)" section showing how to disable specific apps
- Update truth table in architecture.md

**New Section Order**:
1. **Default Behavior** - `enable = true` themes everything
2. **Selective Disabling** - `enable = true` + `<app>.enable = false`
3. **Manual Control** - `autoEnable = false` + manual enables (advanced)

#### D. Architecture Documentation
**File**: `docs/architecture.md`
**Section**: "shouldTheme Logic"
**Changes**:
- Update truth table to reflect new default
- Update example code comments
- Note that `autoEnable = true` is now implicit

**Old Truth Table**:
| Signal enabled | autoEnable | Explicit enable | Program enabled | Result |
|---------------|------------|-----------------|-----------------|--------|
| ✅ | ❌ | ❌ | ✅ | ❌ No theme |

**New Truth Table**:
| Signal enabled | autoEnable | Explicit enable | Program enabled | Result |
|---------------|------------|-----------------|-----------------|--------|
| ✅ | ✅ (default) | ❌ | ✅ | ✅ Theme applied |
| ✅ | ❌ (opt-out) | ❌ | ✅ | ❌ No theme |

#### E. Design Principles
**File**: `docs/design-principles.md`
**Changes**:
- Update "Convention over Configuration" section
- Emphasize zero-config theming as the default
- Show `autoEnable = false` as the exception, not the rule

#### F. Troubleshooting Guide
**File**: `docs/troubleshooting.md`
**Changes**:
- Update flowchart: "Signal enabled?" → "Yes" should now lead to "Programs themed"
- Add section: "How to disable auto-theming" (since it's now default)
- Remove `autoEnable = true` from troubleshooting steps

#### G. Quick Reference
**File**: `docs/semantic-bridge-guide.md`
**Changes**:
- Update all minimal examples to omit `autoEnable = true`
- Add entry: "Disable auto-theming: `autoEnable = false;`"

---

## Example Files Updates

### 3. Example Configurations

#### A. Simplify Basic Examples
**Files**:
- `examples/basic.nix`
- `examples/full-desktop.nix`
- `examples/custom-brand.nix`

**Change**: Remove explicit app enables, rely on autoEnable

**Before** (`examples/basic.nix`):
```nix
theming.signal = {
  enable = true;
  mode = "dark";

  editors = {
    helix.enable = true;
  };

  terminals.ghostty.enable = true;

  cli = {
    bat.enable = true;
    fzf.enable = true;
    yazi.enable = true;
  };
};
```

**After**:
```nix
theming.signal = {
  enable = true;
  mode = "dark";
  # All enabled programs are automatically themed!
};
```

#### B. Update Auto-Enable Example
**File**: `examples/auto-enable.nix`
**Change**: Rename to `examples/selective-disable.nix` or update purpose

**Before**: Shows how to enable `autoEnable = true`
**After**: Shows how to disable specific apps when autoEnable is default

```nix
# Signal themes everything by default
theming.signal = {
  enable = true;
  mode = "dark";

  # Opt-out of specific programs:
  cli.bat.enable = false;  # Keep bat's default theme
  terminals.kitty.enable = false;  # Keep kitty's default theme
};
```

#### C. Update Migration Guide
**File**: `examples/migrating-existing-config.nix`
**Changes**:
- Update migration steps to reflect new default
- Emphasize that step 3 (enable autoEnable) is no longer needed
- Show how to disable auto-theming if desired (opt-out)

**New Steps**:
1. Add Signal to inputs
2. Add `theming.signal.enable = true;`
3. Done! (autoEnable is default)
4. (Optional) Disable specific apps if desired

#### D. Create New Example
**File**: `examples/manual-control.nix` (new)
**Purpose**: Show advanced pattern of disabling autoEnable for manual control

```nix
# Advanced: Manual per-app control (opt-out of auto-theming)
theming.signal = {
  enable = true;
  autoEnable = false;  # Disable automatic theming
  mode = "dark";

  # Now manually enable only what you want:
  editors.helix.enable = true;
  terminals.kitty.enable = true;
};
```

---

## Test Suite Updates

### 4. Test Changes

#### A. Update Existing Tests
**Files**:
- `tests/activation/default.nix`
- `tests/integration/default.nix`
- `tests/comprehensive-test-suite.nix`

**Changes Required**:

1. **Tests with explicit enables** (activation-helix-dark, etc.)
   - **Current**: `enable = true` + `editors.helix.enable = true`
   - **Issue**: With new default, this tests autoEnable AND explicit enable
   - **Fix**: Add `autoEnable = false;` to test only explicit enables

   ```diff
   + theming.signal = {
   +   enable = true;
   +   autoEnable = false;  # ← Disable auto-theming for this test
   +   editors.helix.enable = true;
   + };
   ```

2. **Auto-enable test** (`tests/comprehensive-test-suite.nix` line 571)
   - **Current**: Tests that `autoEnable = true` works
   - **Change**: Now tests default behavior (can remove explicit `autoEnable = true`)

3. **Disabled auto-enable test** (line 592)
   - **Current**: Tests `autoEnable = false`
   - **Keep**: This is still valid (tests opt-out)

#### B. Add New Test Cases
**File**: `tests/integration/default.nix`
**New Tests**:

1. **default-auto-enable-behavior**
   - Verify that `enable = true` alone themes enabled programs
   - No explicit `autoEnable = true` set

2. **opt-out-specific-apps**
   - Verify explicit `<app>.enable = false` works with default autoEnable

3. **opt-out-auto-enable**
   - Verify `autoEnable = false` disables auto-theming
   - Verify manual enables still work

#### C. Update Test Documentation
**File**: `docs/TESTING_GUIDE.md`
**Changes**:
- Update test descriptions to reflect new default
- Add section explaining autoEnable test coverage
- Document opt-out test patterns

---

## Migration Guide for Users

### 5. User Impact & Migration

#### A. Breaking Change Classification
**Severity**: Minor
**Type**: Behavior change (opt-in → opt-out)
**Mitigation**: Easy (one-line change)

#### B. Who Is Affected?

**Not Affected** (majority):
- Users with `autoEnable = true` (most common pattern)
- Users with explicit app enables AND `programs.<app>.enable = true`
- New users (get better defaults)

**Affected** (minority):
- Users with only `enable = true` who expect NO theming
  - **Fix**: Add `autoEnable = false;`

- Users with explicit app enables but `programs.<app>.enable = false`
  - **Impact**: None (programs still not themed since not enabled)

#### C. Migration Path

**For users who want the old behavior** (no auto-theming):

```diff
  theming.signal = {
    enable = true;
+   autoEnable = false;  # ← Opt out of auto-theming
    mode = "dark";
  };
```

#### D. Communication Plan

1. **CHANGELOG Entry** (breaking change section):
   ```markdown
   ### Breaking Changes

   - **autoEnable now defaults to `true`**: When you set `theming.signal.enable = true`,
     Signal will now automatically theme all enabled programs. This makes Signal work
     "out of the box" without requiring `autoEnable = true`.

     **Migration**: If you want the old behavior (no auto-theming), set
     `theming.signal.autoEnable = false;`
   ```

2. **Update Release Notes**: Emphasize this as a UX improvement
3. **Add to Documentation**: "What's New" section in README

---

## Implementation Checklist

### Phase 1: Core Changes
- [ ] Update `modules/common/default.nix` (autoEnable default)
- [ ] Update `modules/nixos/common/default.nix` (autoEnable default)
- [ ] Update option descriptions in both files

### Phase 2: Documentation
- [ ] Update `README.md` (quick start, examples)
- [ ] Update `docs/getting-started.md` (simplify examples)
- [ ] Update `docs/configuration-guide.md` (reorder sections)
- [ ] Update `docs/architecture.md` (truth table, logic flow)
- [ ] Update `docs/design-principles.md` (zero-config emphasis)
- [ ] Update `docs/troubleshooting.md` (flowchart, steps)
- [ ] Update `docs/semantic-bridge-guide.md` (minimal examples)
- [ ] Update `docs/theming-reference.md` (if applicable)

### Phase 3: Examples
- [ ] Simplify `examples/basic.nix`
- [ ] Simplify `examples/full-desktop.nix`
- [ ] Simplify `examples/desktop-complete.nix`
- [ ] Update `examples/auto-enable.nix` (rename or repurpose)
- [ ] Update `examples/migrating-existing-config.nix` (new steps)
- [ ] Update `examples/custom-brand.nix`
- [ ] Create `examples/manual-control.nix` (opt-out pattern)
- [ ] Update `examples/nixos-complete.nix`

### Phase 4: Tests
- [ ] Add `autoEnable = false` to explicit-enable tests
- [ ] Update auto-enable test (now default behavior)
- [ ] Add test: default-auto-enable-behavior
- [ ] Add test: opt-out-specific-apps
- [ ] Add test: opt-out-auto-enable
- [ ] Update `docs/TESTING_GUIDE.md`
- [ ] Run full test suite
- [ ] Verify all tests pass

### Phase 5: Quality Assurance
- [ ] Test in clean environment (fresh install)
- [ ] Verify opt-out pattern works (`autoEnable = false`)
- [ ] Verify explicit disables work (`<app>.enable = false`)
- [ ] Check all examples evaluate correctly
- [ ] Run `nix flake check`
- [ ] Verify NixOS module consistency with Home Manager

### Phase 6: Release
- [ ] Update `CHANGELOG.md` (breaking change section)
- [ ] Add migration guide to CHANGELOG
- [ ] Update version number (minor bump: 0.x.0 → 0.y.0)
- [ ] Create release notes
- [ ] Tag release
- [ ] Update documentation website (if applicable)

---

## Risk Assessment

### Risks

| Risk | Likelihood | Severity | Mitigation |
|------|-----------|----------|------------|
| Users surprised by auto-theming | Medium | Low | Clear CHANGELOG, easy opt-out |
| Tests fail unexpectedly | Low | Medium | Thorough test updates before merge |
| Documentation out of sync | Low | Low | Comprehensive doc update checklist |
| Breaking user configs | Low | Low | Migration guide, one-line fix |

### Benefits

| Benefit | Impact |
|---------|--------|
| Simplified user experience | High |
| Fewer lines of config | Medium |
| "It just works" feeling | High |
| Better defaults for new users | High |
| Aligns with "convention over configuration" | High |

---

## Timeline Estimate

- **Phase 1** (Core Changes): 15 minutes
- **Phase 2** (Documentation): 2-3 hours
- **Phase 3** (Examples): 1-2 hours
- **Phase 4** (Tests): 2-3 hours
- **Phase 5** (QA): 1-2 hours
- **Phase 6** (Release): 1 hour

**Total**: 7-11 hours of work

---

## Open Questions

1. **Should we keep `examples/auto-enable.nix`?**
   - Option A: Delete (no longer needed)
   - Option B: Rename to `examples/selective-disable.nix`
   - Option C: Keep but update to show it's now redundant
   - **Recommendation**: Option B (shows opt-out pattern)

2. **Should autoEnable be shown in minimal examples?**
   - Since it's now default, should we hide it entirely?
   - Or show it commented out with explanation?
   - **Recommendation**: Hide in basic examples, show in advanced docs

3. **Version bump: minor or patch?**
   - This is a breaking change (behavior change)
   - But it's a UX improvement with easy migration
   - **Recommendation**: Minor bump (0.x.0 → 0.y.0)

4. **Timing for release?**
   - Should this go in next release?
   - Or wait for other breaking changes to batch together?
   - **Recommendation**: Next release (standalone is fine)

---

## Success Criteria

- [ ] `theming.signal.enable = true;` themes all enabled programs (no other config needed)
- [ ] `autoEnable = false;` opt-out works correctly
- [ ] Explicit `<app>.enable = false` disables work correctly
- [ ] All tests pass
- [ ] All examples evaluate
- [ ] Documentation is consistent and clear
- [ ] CHANGELOG clearly explains the change
- [ ] No user complaints about unexpected behavior (after release)

---

## References

- Current autoEnable implementation: `lib/default.nix:156`
- shouldTheme logic: `lib/mkAppModule.nix:90-109`
- Architecture docs: `docs/architecture.md`
- Current examples: `examples/` directory
- Test suite: `tests/` directory
