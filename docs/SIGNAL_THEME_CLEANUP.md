# Signal Theme Cleanup & Refinement Checklist

## ? Completed

1. **BGR Conversion Function** - Added to `modules/shared/features/theming/lib.nix`
   - ? Verified correct: `#cdd6f4` (RGB) ? `#f4d6cd` (BGR)
   - ? Available as `theme.formats.bgrHex` and `theme.formats.bgrHexRaw`

2. **Documentation** - Created `docs/SIGNAL_THEME_CORRECT_THEMING.md`
   - ? Complete examples for swaylock, mpv, and niri
   - ? Semantic color mappings
   - ? Format reference table

3. **Shellcheck Fix** - Fixed `pkgs/pog-scripts/cleanup-duplicates.nix`
   - ? Wrapped `confirm` helper in proper if statement

## ?? Recommended Cleanup

### High Priority

#### 1. ? Update `home/nixos/apps/mpv.nix`

**Status**: **COMPLETED**

**Changes Made**:

- ? Added BGR conversion for script-opts (stats plugin)
- ? ? Added UOSC color options with proper RGB hex format
- ? Access `themeLib` from `themeContext.lib` for format conversions
- ? All colors use semantic tokens from Signal theme

**Implementation**:

- Stats script-opts use `theme.formats.bgrHexRaw` for BGR format (#BBGGRR)
- UOSC options use `colors."name".hexRaw` for RGB hex without # prefix
- Follows best practices from `docs/SIGNAL_THEME_CORRECT_THEMING.md`

#### 2. ? Update `home/nixos/apps/swayidle.nix`

**Status**: **COMPLETED**

**Changes Made**:

- ? Moved all color configuration to `programs.swaylock.settings`
- ? Removed color arguments from swayidle command-line
- ? Added proper comments explaining the approach
- ? All colors use semantic tokens from Signal theme

**Implementation**:

- Colors configured via Home Manager's `programs.swaylock.settings` (best practice)
- Command-line only contains non-color arguments (effects, timing, etc.)
- Follows best practices from `docs/SIGNAL_THEME_CORRECT_THEMING.md`

### Medium Priority

#### 3. Review `home/nixos/theme-constants.nix`

**Current State**: Separate file that generates niri colors from Signal theme

**Options**:

- **Keep as-is**: Works fine, provides separation of concerns
- **Refactor**: Use `themeContext` directly in `niri.nix` (would require passing themeContext)

**Recommendation**: Keep as-is for now. It's a clean abstraction and works well.

#### 4. Consider Migration for `home/nixos/launcher.nix` (fuzzel)

**Current State**: Manually uses `themeContext`

**Action**: Could migrate to use Signal theme module (`theming.signal.applications.fuzzel.enable`)

**Note**: Current approach works fine. Migration is optional.

#### 5. Consider Migration for `home/nixos/apps/swappy.nix`

**Current State**: Manually uses `themeContext`

**Action**: Could migrate to use Signal theme module (`theming.signal.applications.swappy.enable`)

**Note**: Current approach works fine. Migration is optional.

### Low Priority

#### 6. Documentation Updates

- ? `docs/SIGNAL_THEME_MISSING_APPS.md` - Already lists manual theming
- ? `docs/SIGNAL_THEME_CORRECT_THEMING.md` - Shows correct approaches
- Consider adding migration guide for moving from manual to module-based theming

#### 7. Code Consistency

- All manual theming files use similar pattern (themeContext with fallback)
- Pattern is consistent and documented
- No conflicts or duplicates found

## ?? Files to Review

### Files Using Manual Theming (themeContext)

- `home/nixos/apps/mpv.nix` - ?? Needs BGR conversion
- `home/nixos/apps/swayidle.nix` - ?? Should use programs.swaylock.settings
- `home/nixos/apps/swappy.nix` - ? Works, optional migration
- `home/nixos/launcher.nix` - ? Works, optional migration
- `home/nixos/niri.nix` - ? Uses theme-constants.nix (fine)

### Files Using Signal Theme Modules

- `modules/shared/features/theming/applications/*` - ? All use semantic tokens correctly
- `home/common/theming/default.nix` - ? Proper integration
- `modules/nixos/features/theming/default.nix` - ? Proper integration

## ?? Action Items

1. ? **Completed**: Update mpv.nix with BGR conversion
2. ? **Completed**: Update swayidle.nix to use programs.swaylock.settings
3. **Optional**: Consider creating Signal theme modules for mpv and swaylock
4. **Optional**: Migrate fuzzel and swappy to use modules (if desired)

## ?? Verification

- ? BGR conversion tested and verified
- ? No linter errors
- ? Documentation complete
- ? No duplicate color definitions
- ? Semantic token usage is consistent

## ?? Notes

- Manual theming via `themeContext` is a valid approach for apps without modules
- `theme-constants.nix` provides a clean abstraction for niri colors
- All approaches are documented and consistent
- ? **All high-priority improvements completed**: mpv BGR conversion and swaylock settings migration done
- ? Both files now follow best practices as documented in `SIGNAL_THEME_CORRECT_THEMING.md`
