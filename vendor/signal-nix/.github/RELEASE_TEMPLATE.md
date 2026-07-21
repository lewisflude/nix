# Release Template

Use this template when creating a new release.

## Version: v1.x.x

**Release Date**: YYYY-MM-DD

---

## 🎉 Highlights

<!-- 2-3 sentence summary of the most important changes -->

## ✨ New Features

<!-- List new features with brief descriptions -->

- **Feature Name**: Description of the feature and how to use it
  ```nix
  # Example configuration
  theming.signal.newFeature.enable = true;
  ```

## 🐛 Bug Fixes

<!-- List bug fixes with issue references -->

- Fixed issue where... (fixes #123)
- Resolved problem with... (fixes #456)

## 🔧 Improvements

<!-- List improvements, enhancements, optimizations -->

- Improved performance of...
- Enhanced color contrast for...
- Optimized module evaluation...

## 📚 Documentation

<!-- List documentation updates -->

- Added troubleshooting guide
- Updated configuration examples
- Improved README with...

## 🔨 Internal Changes

<!-- List internal changes, refactoring, CI/CD updates -->

- Refactored color token system
- Updated CI workflows
- Improved test coverage

## ⚠️ Breaking Changes

<!-- List any breaking changes and migration instructions -->

**NONE** in this release. Signal v1.x maintains backwards compatibility.

<!-- OR if there are breaking changes: -->

### Migration Required

**Change Description:**
- Old way: `theming.signal.oldOption = ...;`
- New way: `theming.signal.newOption = ...;`

**Migration steps:**
1. Update your configuration
2. Rebuild with `home-manager switch`
3. Verify changes

## 📦 New Application Support

<!-- List newly supported applications -->

- ✅ **App Name** - Description
  ```nix
  theming.signal.category.appName.enable = true;
  ```

## 🎨 Color & Theme Updates

<!-- List color palette or theme changes -->

- Adjusted contrast for...
- Refined light mode colors...
- Improved syntax highlighting for...

## 🔄 Dependency Updates

<!-- List dependency updates -->

- Updated signal-palette to v1.x.x
- Updated home-manager compatibility
- Updated nixpkgs compatibility

## 📊 Statistics

<!-- Optional: Include statistics about the release -->

- **Commits**: XX since last release
- **Contributors**: X people
- **Files Changed**: XX files
- **Lines Added**: +XXX
- **Lines Removed**: -XXX
- **Supported Applications**: XX total

## 🙏 Contributors

<!-- Thank contributors -->

Thanks to everyone who contributed to this release:

- @username1 - Feature implementation
- @username2 - Bug fixes
- @username3 - Documentation

And thanks to all who reported issues and provided feedback!

## 📖 Documentation

- **Quick Start**: https://github.com/lewisflude/signal-nix#quick-start
- **Configuration Guide**: https://github.com/lewisflude/signal-nix/blob/main/docs/README.md
- **Troubleshooting**: https://github.com/lewisflude/signal-nix/blob/main/docs/troubleshooting.md
- **Contributing**: https://github.com/lewisflude/signal-nix/blob/main/CONTRIBUTING.md

## 🔗 Resources

- **signal-palette**: https://github.com/lewisflude/signal-palette
- **Examples**: https://github.com/lewisflude/signal-nix/tree/main/examples
- **Issues**: https://github.com/lewisflude/signal-nix/issues
- **Discussions**: https://github.com/lewisflude/signal-nix/discussions

## 📥 Installation

### New Installation

Add to your flake inputs:

```nix
{
  inputs.signal.url = "github:lewisflude/signal-nix/v1.x.x";
}
```

### Upgrade from Previous Version

Update your flake lock:

```bash
nix flake update signal
home-manager switch --flake .#
```

## ✅ Verification

After upgrading, verify the installation:

```bash
# Check version
nix flake metadata signal

# Verify module loads
nix eval .#homeManagerModules.default

# Rebuild
home-manager switch --flake .#
```

## 🐛 Known Issues

<!-- List any known issues with workarounds -->

- Issue description (tracking in #XXX)
  - **Workaround**: Description of workaround

OR

No known issues in this release.

## 🗺️ Roadmap

### Next Release (v1.x.x)

Planned for next release:

- [ ] Feature A
- [ ] Feature B
- [ ] Bug fix for #XXX

### Future Releases

- Additional application integrations
- Light mode refinements
- Performance optimizations
- Community showcase

## 💬 Feedback

We value your feedback! Please:

- 🐛 Report bugs via [GitHub Issues](https://github.com/lewisflude/signal-nix/issues/new/choose)
- 💡 Suggest features via [GitHub Discussions](https://github.com/lewisflude/signal-nix/discussions)
- 🎨 Share your setup in [Show and Tell](https://github.com/lewisflude/signal-nix/discussions/categories/show-and-tell)
- ⭐ Star the repository if you find it useful!

## 📜 Changelog

For detailed changes, see [CHANGELOG.md](https://github.com/lewisflude/signal-nix/blob/main/CHANGELOG.md).

---

**Full Changelog**: https://github.com/lewisflude/signal-nix/compare/v1.x.x...v1.x.x

**Perception, engineered.** 🎨✨
