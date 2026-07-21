# Signal-Nix Test Suite

This directory contains the comprehensive test suite for the Signal Design System.

> **For detailed testing documentation, see [docs/TESTING_GUIDE.md](../docs/TESTING_GUIDE.md)**

## Quick Start

```bash
# From the project root
./run-tests.sh --all
```

## Test Files

### `default.nix`
The main test file that imports and organizes all tests. Contains:
- Test helper functions (`mkTest`, `mkModuleTest`, etc.)
- Unit tests for library functions
- Integration tests for examples
- Module structure tests
- Edge case tests
- Accessibility tests
- Color manipulation tests
- Imports from `comprehensive-test-suite.nix`

### `comprehensive-test-suite.nix`
Extended test suite covering:
- **Happy Path** (6 tests): Normal usage patterns
- **Edge Cases** (6 tests): Boundary conditions
- **Error Handling** (3 tests): Invalid input rejection
- **Integration** (12 tests): Component interactions
- **Performance** (4 tests): Speed and resource usage
- **Security** (5 tests): Input validation and safety
- **Documentation** (2 tests): Example and doc validation

## Test Categories

### 1. Unit Tests (5 tests)
Test individual library functions in isolation.

```bash
./run-tests.sh --category unit
```

Tests:
- `unit-lib-resolveThemeMode`: Theme mode resolution
- `unit-lib-isValidResolvedMode`: Resolved mode validation
- `unit-lib-getThemeName`: Theme name generation
- `unit-lib-getColors`: Color palette retrieval
- `unit-lib-getSyntaxColors`: Syntax color retrieval

### 2. Integration Tests (11 tests)
Test component interactions and example configurations.

```bash
./run-tests.sh --category integration
```

Tests include:
- Module-library interaction
- Color-syntax coordination
- Brand governance merging
- Theme resolution consistency
- Auto-enable logic
- Example configurations (basic, auto-enable, full-desktop, custom-brand)
- Module build validation

### 3. Module Tests (8 tests)
Test individual module structure and evaluation.

```bash
./run-tests.sh --category module
```

Tests:
- Common module
- Editor modules (Helix)
- Terminal modules (Ghostty)
- CLI modules (Bat, Fzf)
- GTK module
- Ironbar module

### 4. Edge Case Tests (8 tests)
Test boundary conditions and unusual inputs.

```bash
./run-tests.sh --category edge
```

Tests:
- Empty brand colors
- Lightness boundaries (0.0, 1.0)
- Chroma boundaries (0.0)
- Contrast extremes
- All modules disabled
- Ironbar profiles
- Multiple terminals
- Brand governance policies

### 5. Error Handling Tests (3 tests)
Test invalid input rejection.

```bash
./run-tests.sh --category error
```

Tests:
- Invalid theme modes
- Invalid brand policies
- Color manipulation error throwing

### 6. Performance Tests (4 tests)
Test speed and resource usage.

```bash
./run-tests.sh --category performance
```

Tests:
- Color lookup speed
- Theme resolution caching
- Large brand color sets (50+ colors)
- Module evaluation time

### 7. Security Tests (5 tests)
Test input validation and safety.

```bash
./run-tests.sh --category security
```

Tests:
- Hex color validation
- Code injection prevention
- Enum validation (mode, policy)
- Path traversal prevention

### 8. Validation Tests (3 tests)
Test consistency across codebase.

```bash
./run-tests.sh --category validation
```

Tests:
- Theme name consistency
- No "signal-auto" usage
- Accessibility contrast estimation

### 9. Documentation Tests (2 tests)
Test documentation accuracy.

```bash
./run-tests.sh --category documentation
```

Tests:
- Example file syntax validity
- README reference accuracy

## Test Helpers

### `mkTest`
Create a pure Nix test comparing expressions:

```nix
mkTest "test-name" {
  testCase = {
    expr = actualValue;
    expected = expectedValue;
  };
}
```

### `mkModuleTest`
Test module file structure:

```nix
mkModuleTest "module-name" ./path/to/module.nix "programName"
```

### `mkExampleTest`
Validate example configurations:

```nix
mkExampleTest "example-name" ./path/to/example.nix "required-pattern"
```

### `mkThemeResolutionTest`
Test theme resolution patterns:

```nix
mkThemeResolutionTest "test-name" ./module.nix "pattern" "description"
```

### `assertFileExists`
Shell assertion for file existence:

```nix
assertFileExists path "description"
```

### `assertFileContains`
Shell assertion for file contents:

```nix
assertFileContains path "pattern" "description"
```

## Running Tests

### Using the test runner script

```bash
# Run all tests
./run-tests.sh --all

# Run specific category
./run-tests.sh --category integration

# Run specific test
./run-tests.sh happy-basic-dark-mode

# List all tests
./run-tests.sh --list

# Verbose output
./run-tests.sh --verbose test-name

# Different system
./run-tests.sh --system aarch64-darwin
```

### Using Nix directly

```bash
# Run all tests
nix flake check

# Run specific test
nix build .#checks.x86_64-linux.unit-lib-getColors

# Show build logs
nix flake check --print-build-logs

# Specific system
nix flake check --system aarch64-darwin
```

## Writing New Tests

### Step 1: Choose the right file

- **Unit/Integration/Module tests**: Add to `default.nix`
- **Happy/Edge/Error/Performance/Security tests**: Add to `comprehensive-test-suite.nix`

### Step 2: Write the test

```nix
# In comprehensive-test-suite.nix
my-new-test = mkTest "my-new-test" {
  testDescription = {
    expr = signalLib.someFunction "input";
    expected = "expected-output";
  };
};
```

### Step 3: Export the test

```nix
# At the end of the file
{
  inherit
    my-new-test
    # ... other tests
    ;
}
```

### Step 4: Add to default.nix

```nix
# In default.nix
inherit
  (import ./comprehensive-test-suite.nix { inherit pkgs lib self home-manager signal-palette system; })
  my-new-test
  # ... other tests
  ;
```

### Step 5: Add to flake.nix

```nix
# In flake.nix under checks
inherit (allTests)
  my-new-test
  ;
```

### Step 6: Test it

```bash
./run-tests.sh my-new-test
```

## Test Naming Convention

Format: `{category}-{description}`

Categories:
- `happy`: Happy path tests
- `edge`: Edge case tests
- `error`: Error handling tests
- `integration`: Integration tests
- `performance`: Performance tests
- `security`: Security tests
- `unit`: Unit tests
- `module`: Module tests
- `validation`: Validation tests
- `documentation`: Documentation tests

Examples:
- `happy-basic-dark-mode`
- `edge-lightness-boundaries`
- `error-invalid-theme-mode`
- `integration-auto-enable-logic`
- `performance-color-lookups`
- `security-no-code-injection`

## CI/CD Integration

Tests run automatically via GitHub Actions on:
- **Pull requests**: All tests
- **Push to main**: All tests
- **Daily schedule**: All tests (catches upstream issues)
- **Manual trigger**: Via workflow_dispatch

See `.github/workflows/test-suite.yml` for details.

## Test Coverage

```
Total Tests: 55
├── Happy Path: 6
├── Edge Cases: 8
├── Error Handling: 3
├── Integration: 11
├── Performance: 4
├── Security: 5
├── Unit Tests: 5
├── Module Tests: 8
├── Validation: 3
└── Documentation: 2
```

## Performance Benchmarks

Current performance targets:

| Metric | Target | Status |
|--------|--------|--------|
| Module evaluation | < 10s | ✓ 2-5s |
| Color lookup | < 1ms | ✓ ~0.1ms |
| Theme resolution | < 1ms | ✓ ~0.1ms |
| Full test suite | < 5min | ✓ 2-3min |

## Troubleshooting

### Test won't build

```bash
# Check syntax
nix-instantiate --parse tests/default.nix

# Check flake
nix flake show
```

### Test fails

```bash
# Show detailed logs
./run-tests.sh --verbose failing-test-name

# Or with nix
nix build .#checks.x86_64-linux.failing-test-name --print-build-logs
```

### All tests fail

```bash
# Update flake inputs
nix flake update

# Clean and rebuild
nix flake check --refresh
```

## Resources

- [TESTING_GUIDE.md](../docs/TESTING_GUIDE.md): Complete test documentation
- [TEST_SUMMARY.md](../TEST_SUMMARY.md): Quick reference and stats
- [CONTRIBUTING.md](../CONTRIBUTING.md): Contributing guidelines

## Quick Reference Card

```bash
# Most common commands
./run-tests.sh --all                    # Run all tests
./run-tests.sh --category integration   # Run category
./run-tests.sh test-name                # Run one test
./run-tests.sh --list                   # List all tests
./run-tests.sh --verbose test-name      # Debug test

nix flake check                         # Nix native
nix build .#checks.x86_64-linux.test    # Specific test
```

---

**Total Tests**: 55
**Test Coverage**: Comprehensive
**CI Status**: Automated
**Last Updated**: 2026-01-17
