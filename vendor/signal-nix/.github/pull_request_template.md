## Description

<!-- Provide a clear and concise description of your changes -->

## Type of Change

<!-- Mark the relevant option(s) with an [x] -->

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🎨 Style/formatting change
- [ ] ♻️ Code refactoring (no functional changes)
- [ ] ⚡ Performance improvement
- [ ] ✅ Test addition or update
- [ ] 🔧 Configuration change
- [ ] 📦 Dependency update

## Related Issues

<!-- Link any related issues using #issue-number or full URLs -->

Closes #
Related to #

## Changes Made

<!-- List the specific changes you made -->

- 
- 
- 

## Testing

<!-- Describe the testing you've done -->

### Test Configuration

```nix
# Your test configuration
theming.signal = {
  enable = true;
  # ...
};
```

### Test Results

- [ ] Tested on NixOS
- [ ] Tested on nix-darwin
- [ ] Tested in dark mode
- [ ] Tested in light mode
- [ ] All examples build successfully
- [ ] No regressions in existing functionality

### System Information

- **OS**: <!-- NixOS 24.05 / macOS Sonoma / etc. -->
- **nixpkgs**: <!-- unstable / 24.05 / commit hash -->
- **Architecture**: <!-- x86_64-linux / aarch64-darwin / etc. -->

## Screenshots/Videos

<!-- If applicable, add screenshots or screen recordings to demonstrate your changes -->

### Before

<!-- Screenshots showing the issue or previous behavior -->

### After

<!-- Screenshots showing the fix or new behavior -->

## Breaking Changes

<!-- If this PR includes breaking changes, describe them and provide migration instructions -->

### Migration Guide

```nix
# Before
theming.signal.oldOption = "value";

# After
theming.signal.newOption = "value";
```

## Checklist

<!-- Mark completed items with an [x] -->

### Code Quality

- [ ] My code follows the Nix style guide
- [ ] I have run `nix fmt` to format my code
- [ ] I have run `statix check` and fixed all issues
- [ ] I have run `deadnix` and removed unused code
- [ ] My code builds without errors (`nix flake check`)
- [ ] I have tested my changes locally

### Documentation

- [ ] I have updated the README if necessary
- [ ] I have added/updated code comments for complex logic
- [ ] I have updated the CHANGELOG.md
- [ ] I have added/updated examples if introducing new features
- [ ] I have added inline documentation for new options

### Compatibility

- [ ] My changes are backwards compatible
- [ ] OR I have documented breaking changes with migration guide
- [ ] My changes work on all supported platforms (Linux, macOS)
- [ ] My changes work with both NixOS and nix-darwin

### Signal Philosophy

- [ ] My changes align with Signal's scientific approach
- [ ] Color changes maintain OKLCH perceptual uniformity
- [ ] New colors meet APCA accessibility standards
- [ ] Brand governance is respected (if applicable)

## Additional Context

<!-- Add any other context about the PR here -->

## Reviewer Notes

<!-- Any specific areas you'd like reviewers to focus on? -->

---

**For Maintainers:**

- [ ] Code review completed
- [ ] Tests pass in CI
- [ ] Documentation is adequate
- [ ] Breaking changes are clearly documented
- [ ] CHANGELOG.md is updated
