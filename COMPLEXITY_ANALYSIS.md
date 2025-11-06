# Code Complexity Analysis

This document identifies files that are too complicated, not as simple as they could be, not following best practices, overengineered, or confusing.

**Generated:** 2025-01-27

---

## 🔴 High Priority: Overengineered / Unnecessary Abstraction

### 1. `lib/overlay-builder.nix` - **UNNECESSARY WRAPPER**

**Issues:**

- Adds an unnecessary layer of indirection
- Just wraps `foldl' composeExtensions` which is already simple
- Used only once in `flake-parts/core.nix`
- Makes overlay composition harder to understand

**Current Code:**

```nix
{
  inputs,
  system,
}:
final: prev:
let
  overlaySet = import ../overlays {
    inherit inputs;
    inherit system;
  };
  overlayList = builtins.attrValues overlaySet;
  inherit (prev.lib) composeExtensions foldl';
in
(foldl' composeExtensions (_: _: { }) overlayList) final prev
```

**Recommendation:**

- **DELETE** this file entirely
- Use overlay composition directly in `flake-parts/core.nix` or `overlays/default.nix`
- The overlay set from `overlays/default.nix` can be converted to a list directly

**Impact:** Low risk - simplifies codebase, removes confusion

---

## 🟠 Medium-High Priority: Too Complicated / Too Long

### 2. `home/common/apps/zed-editor.nix` - **416 LINES, HIGHLY REPETITIVE**

**Issues:**

- Extremely long file (416 lines)
- Massive repetition in language server configurations
- TypeScript and JavaScript configs are nearly identical (lines 157-184)
- Multiple language configs follow same pattern (tab_size, formatter, code_actions)
- Hard to maintain and modify

**Examples of Repetition:**

- Lines 288-318: TypeScript config
- Lines 300-330: TSX config (nearly identical)
- Lines 331-342: CSS config (same pattern)
- Lines 344-365: JSON/JSONC configs (identical pattern)

**Recommendation:**

- Extract language server configs into a helper function
- Create a shared config builder for similar languages
- Split into multiple files:
  - `zed-editor.nix` - main config
  - `zed-editor-languages.nix` - language-specific configs
  - `zed-editor-lsp.nix` - LSP server configs

**Example Refactor:**

```nix
# Helper function for similar language configs
mkBiomeLanguage = tabSize: {
  tab_size = tabSize;
  code_actions_on_format."source.fixAll.biome" = true;
  formatter.language_server.name = "biome";
};

# Then use:
languages = {
  JavaScript = mkBiomeLanguage 2;
  TypeScript = mkBiomeLanguage 2 // { inlay_hints = {...}; };
  TSX = mkBiomeLanguage 2;
  CSS = mkBiomeLanguage 2;
  # etc.
};
```

**Impact:** Medium - improves maintainability significantly

---

### 3. `home/common/shell.nix` - **408 LINES, COMPLEX SHELL CONFIG**

**Issues:**

- Very long file (408 lines)
- Large amounts of inline shell code in strings (lines 258-364)
- Complex palette detection logic (lines 19-30) with nested conditionals
- Secret export snippet generation (lines 33-40) could be simpler
- Hard to test individual components

**Specific Problems:**

1. **Palette detection** (lines 19-30): Deeply nested conditionals

   ```nix
   palette = if ... then ... else if ... then let ... in if ... then ... else throw ...
   ```

   This could use `lib.optionals` or a helper function

2. **Secret export snippets** (lines 33-40): Could be a simple function
3. **Large initContent block** (lines 258-364): 100+ lines of shell code in a Nix string

**Recommendation:**

- Extract palette detection to a helper function in `lib/`
- Extract secret export logic to a helper
- Consider moving some shell config to separate `.zsh` files managed by Home Manager
- Split into:
  - `shell.nix` - main config
  - `shell-palette.nix` - palette detection logic
  - `shell-secrets.nix` - secret export logic

**Impact:** Medium - improves readability and testability

---

## 🟡 Medium Priority: Not as Simple as They Could Be

### 4. `home/common/apps/core-tooling.nix` & `packages.nix` - **DUPLICATE PATTERNS**

**Issues:**

- Both files have similar structure
- Both import `lib/functions.nix` to get `withSystem`
- Both have the same `nx` fallback logic (lines 10-16 in both)
- Both use `platformLib.platformPackages` with similar patterns

**Current Pattern:**

```nix
# In both files:
platformLib = (import ../../../lib/functions.nix {inherit lib;}).withSystem system;
nx = if pkgs ? nx-latest then pkgs.nx-latest else if pkgs.nodePackages ? nx then pkgs.nodePackages.nx else null;
```

**Recommendation:**

- Extract `nx` detection to a shared helper
- Consider consolidating if they serve similar purposes
- Or create a shared `apps-helpers.nix` file

**Impact:** Low - reduces duplication

---

### 5. `lib/package-sets.nix` - **REPETITIVE WITH PKGS PATTERNS**

**Issues:**

- Multiple `with pkgs;` blocks (lines 13, 28, 41, 55, 64, 76, 84, 90, 101, 108, 115, 124, 138, 143, 150)
- Repetitive toolchain definitions
- Could use helper functions to reduce repetition

**Example:**

```nix
# Current - repetitive:
rustToolchain = if pkgs ? fenix && pkgs.fenix ? stable then
  with pkgs; [ ... ]
else
  with pkgs; [ ... ];

pythonToolchain = pkgs: with pkgs; [ ... ];
goToolchain = with pkgs; [ ... ];
```

**Recommendation:**

- Create helper functions for common patterns
- Consider using `lib.mapAttrs` for similar toolchains
- Extract common package groups

**Impact:** Low - cosmetic improvement

---

### 6. `overlays/default.nix` - **REPETITIVE CONDITIONAL PATTERNS**

**Issues:**

- Multiple similar conditional patterns for flake inputs
- Lines 24-31, 37-54, 56-67, 69-80 all follow similar pattern:

  ```nix
  if inputs ? X && inputs.X ? Y then ... else (_final: _prev: { })
  ```

**Examples:**

- `nh` overlay (lines 24-25)
- `nix-topology` overlay (lines 27-31)
- `fenix-overlay` (lines 37-54) - especially complex with workaround comments
- `lazygit` (lines 56-67)
- `atuin` (lines 69-80)

**Recommendation:**

- Create a helper function:

  ```nix
  mkOptionalOverlay = cond: overlay: if cond then overlay else (_: _: {});
  mkFlakeOverlay = inputName: path:
    mkOptionalOverlay (inputs ? ${inputName} && lib.hasAttrByPath path inputs)
      (lib.getAttrFromPath path inputs);
  ```

**Impact:** Low - reduces repetition

---

### 7. `lib/system-builders.nix` - **LONG CONDITIONAL CHAINS**

**Issues:**

- Very long module lists with many `lib.optionals` (lines 60-108 for Darwin, 125-165 for NixOS)
- Repetitive conditional module inclusion patterns
- Hard to see which modules are included for which platforms

**Example:**

```nix
++ lib.optionals (determinate != null) [determinate.darwinModules.default]
++ lib.optionals (home-manager != null) [home-manager.darwinModules.home-manager]
++ lib.optionals (mac-app-util != null) [mac-app-util.darwinModules.default]
# ... 10+ more similar lines
```

**Recommendation:**

- Extract module lists to helper functions:

  ```nix
  mkDarwinModules = {inputs, ...}: [
    ../modules/darwin/default.nix
  ] ++ optionalModules [
    { cond = inputs ? determinate; module = inputs.determinate.darwinModules.default; }
    { cond = inputs ? home-manager; module = inputs.home-manager.darwinModules.home-manager; }
    # ...
  ];
  ```

**Impact:** Medium - improves readability

---

## 🟢 Low Priority: Minor Improvements

### 8. `lib/functions.nix` - **SOME REDUNDANCY**

**Issues:**

- Lines 157-184: Multiple `inherit` statements that could be consolidated
- Some functions are very similar (e.g., `platformPackages`, `platformModules`, `platformConfig`, `platformPackage`)

**Recommendation:**

- Consolidate `inherit` statements
- Consider if some platform functions can be generalized

**Impact:** Very Low - mostly cosmetic

---

### 9. `home/common/ssh.nix` - **COULD BE SIMPLER**

**Issues:**

- Uses `extraOptions` as an attrset when it could use `extraConfig` (more idiomatic)
- The `"*"` match block could be clearer

**Current:**

```nix
extraOptions = {
  StrictHostKeyChecking = "accept-new";
  # ...
};
```

**Better:**

```nix
extraConfig = ''
  StrictHostKeyChecking accept-new
  # ...
'';
```

**Impact:** Very Low - minor improvement

---

## 📊 Summary Statistics

| Priority | Count | Files |
|----------|-------|-------|
| 🔴 High | 1 | `lib/overlay-builder.nix` |
| 🟠 Medium-High | 2 | `home/common/apps/zed-editor.nix`, `home/common/shell.nix` |
| 🟡 Medium | 4 | `home/common/apps/core-tooling.nix`, `lib/package-sets.nix`, `overlays/default.nix`, `lib/system-builders.nix` |
| 🟢 Low | 2 | `lib/functions.nix`, `home/common/ssh.nix` |

---

## 🎯 Recommended Action Plan

### Phase 1: Quick Wins (High Impact, Low Effort)

1. **Delete `lib/overlay-builder.nix`** - Simplest change, removes confusion
2. **Refactor `overlays/default.nix`** - Add helper function for conditional overlays

### Phase 2: Maintainability Improvements (Medium Effort)

3. **Split `zed-editor.nix`** - Extract language configs to separate files/helpers
4. **Simplify `shell.nix`** - Extract palette and secret logic to helpers

### Phase 3: Code Quality (Lower Priority)

5. **Consolidate `core-tooling.nix` and `packages.nix`** patterns
6. **Refactor `system-builders.nix`** module lists
7. **Improve `package-sets.nix`** with helper functions

---

## ✅ What's Already Good

Your codebase is generally well-structured! These are optimizations, not critical issues:

- ✅ Good use of `mkIf` for conditional configuration
- ✅ Proper module organization
- ✅ Good separation of concerns
- ✅ Most `with pkgs;` usage is appropriate (limited scope)
- ✅ Well-documented architecture

The issues identified are mostly about **reducing repetition** and **improving maintainability**, not fundamental problems.
