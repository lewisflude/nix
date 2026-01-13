# TODO: Future Refactoring Tasks

This document tracks potential refactorings and improvements identified during code audits.

## High Priority

_No high priority items at this time._

---

## Medium Priority

_No medium priority items at this time._

---

## Low Priority (Already Justified)

### 9. Darwin Nix Daemon Management

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

---

## New Tasks (2026-01-13 Automated Analysis)

### Refactor Host Ports to Constants

**Location:** `hosts/jupiter/default.nix`

**Issue:**
Hardcoded port values found in host configuration:

- `termix.port = 8083`
- `calcom.port = 3000`
- `calcom.email.port = 465`
- `qbittorrent.webUI.port = 8080`

**Proposed Solution:**
Replace hardcoded values with references to `lib/constants.nix`.

### Remove `with pkgs;` Antipattern

**Location:** `shells/projects/vr.nix`

**Issue:**
Strictly forbidden `with pkgs;` usage detected:

```nix
buildInputs = with pkgs; [
```

**Proposed Solution:**
Replace with explicit package references (e.g., `pkgs.foo`, `pkgs.bar`).

### Correct Audio Feature Documentation

**Location:** `docs/FEATURES.md`

**Issue:**
Documentation refers to `host.features.audio` but codebase uses `host.features.media.audio`.

**Proposed Solution:**
Update documentation to reflect the correct nesting under `media`.

## Completed Items (Previous)

### ~~Implement Missing Productivity Features~~ ✅

[... truncated for brevity ...]
