# Signal Testing Guide

> **A comprehensive guide to writing and running tests for Signal Design System**

This guide explains how to write effective tests for Signal modules, when to use different test types, and how to debug test failures. It's designed for contributors adding new application modules or improving existing functionality.

## Table of Contents

- [Overview](#overview)
- [Test Structure](#test-structure)
- [When to Use Each Test Type](#when-to-use-each-test-type)
- [Writing Unit Tests](#writing-unit-tests)
- [Writing Integration Tests](#writing-integration-tests)
- [Running Tests](#running-tests)
- [Debugging Test Failures](#debugging-test-failures)
- [Test Requirements for New Modules](#test-requirements-for-new-modules)
- [Test Templates](#test-templates)
- [Common Testing Patterns](#common-testing-patterns)
- [Performance Considerations](#performance-considerations)
- [CI/CD Integration](#cicd-integration)

## Overview

Signal-nix uses a **hybrid testing approach** combining:

- **Unit tests** - Fast, pure Nix tests for library functions
- **Integration tests** - Shell-based validation for module structure and examples
- **Static checks** - Format validation and structural verification

### Testing Philosophy

1. **Pure Nix First**: Use unit tests for anything that can be tested without shell commands
2. **Fast Feedback**: Tests should complete in seconds, not minutes
3. **Deterministic**: Same input always produces same output
4. **Clear Errors**: Test failures should pinpoint the exact problem
5. **CI-First**: All tests run automatically on every change

### Test Coverage Summary

| Category | Tests | Location | Type |
|----------|-------|----------|------|
| Library Functions | 5 | `tests/unit/` | Unit |
| Brand Governance | 1 | `tests/unit/` | Unit |
| Accessibility | 1 | `tests/unit/` | Unit |
| Color Manipulation | 2 | `tests/unit/` | Unit |
| Example Configs | 6 | `tests/integration/` | Integration |
| Module Structure | 12 | `tests/integration/` | Integration |
| Edge Cases | 4 | `tests/integration/` | Integration |
| Theme Validation | 2 | `tests/integration/` | Integration |
| **Total** | **33** | - | - |

## Test Structure

Tests are organized into two main directories:

```
tests/
├── default.nix              # Main aggregator (imports from subdirectories)
├── unit/
│   └── default.nix          # Pure Nix unit tests (9 tests)
├── integration/
│   └── default.nix          # Shell-based validation (15 tests)
├── nixos.nix               # NixOS-specific tests
└── comprehensive-test-suite.nix  # Additional scenarios
```

### Why This Structure?

- **Clear Separation**: Pure tests vs shell tests are immediately distinguishable
- **Performance**: Easy to run only fast unit tests during development
- **Maintainability**: Related tests grouped together in focused files
- **Future-Ready**: Prepares for potential nix-unit migration

## When to Use Each Test Type

### Use Unit Tests (`tests/unit/`) When:

✅ Testing pure functions that take input and return output  
✅ No file system access needed  
✅ Fast execution is critical (< 1 second per test)  
✅ Testing mathematical operations or transformations  

**Examples:**
- Color calculations (`adjustLightness`, `adjustChroma`)
- Theme resolution (`resolveThemeMode`, `getThemeName`)
- Accessibility checks (`estimateContrast`, `meetsMinimum`)
- Brand governance logic (`mergeColors`)

**Characteristics:**
- Use `lib.runTests` for evaluation
- No shell commands or external tools
- Runs in ~0.5-1 second per test
- Ideal for TDD (Test-Driven Development)

### Use Integration Tests (`tests/integration/`) When:

✅ Validating file structure and existence  
✅ Pattern matching with grep  
✅ Checking module configuration structure  
✅ Testing example configurations  

**Examples:**
- Module validation (file exists, contains expected patterns)
- Example syntax verification
- Configuration structure checks
- Theme resolution consistency across modules

**Characteristics:**
- Use `pkgs.runCommand` with shell scripts
- File system access required
- Runs in ~2-5 seconds per test
- Run before commits or in CI

### Quick Decision Tree

```
Is it a pure function?
├─ Yes → Use Unit Test
└─ No → Does it need file access or grep?
    ├─ Yes → Use Integration Test
    └─ No → Consider if it should be a pure function
```

## Writing Unit Tests

Unit tests use Nix's built-in `lib.runTests` function for pure evaluation.

### Unit Test Template

```nix
# tests/unit/default.nix

unit-my-function = mkTest "my-function" {
  testCase1 = {
    expr = signalLib.myFunction "input";
    expected = "expected-output";
  };
  
  testCase2 = {
    expr = signalLib.myFunction "other-input";
    expected = "other-output";
  };
  
  testEdgeCase = {
    expr = signalLib.myFunction "";
    expected = "default";
  };
};
```

### Key Components

1. **Test Name**: Descriptive identifier (`unit-my-function`)
2. **Test Cases**: Multiple cases testing different inputs
3. **Expression**: The function call to test (`expr`)
4. **Expected**: The expected result (`expected`)

### Example: Testing a Color Function

```nix
unit-lib-adjustLightness = mkTest "lib-adjust-lightness" {
  testLightnessIncrease = {
    expr = 
      let
        color = { l = 0.5; c = 0.1; h = 180.0; hex = "#808080"; };
        adjusted = signalLib.colors.adjustLightness { 
          inherit color; 
          delta = 0.2; 
        };
      in
        adjusted.l > color.l;
    expected = true;
  };
  
  testChromaPreserved = {
    expr = 
      let
        color = { l = 0.5; c = 0.1; h = 180.0; hex = "#808080"; };
        adjusted = signalLib.colors.adjustLightness { 
          inherit color; 
          delta = 0.2; 
        };
      in
        adjusted.c == color.c;
    expected = true;
  };
};
```

### Exporting Unit Tests

After writing your test, export it in `tests/default.nix`:

```nix
# tests/default.nix
{
  inherit (unitTests)
    unit-lib-resolveThemeMode
    unit-lib-getColors
    unit-my-function  # Add your test here
    ;
}
```

### Unit Test Best Practices

1. **Test One Thing**: Each test case should verify a single behavior
2. **Use Descriptive Names**: `testLightnessIncrease` is better than `test1`
3. **Test Edge Cases**: Empty strings, zero values, boundary conditions
4. **Keep It Pure**: No side effects, file I/O, or external dependencies
5. **Multiple Cases**: Test happy path, edge cases, and error conditions

## Writing Integration Tests

Integration tests use `pkgs.runCommand` to run shell commands for validation.

### Integration Test Template

```nix
# tests/integration/default.nix

module-myapp-evaluates = pkgs.runCommand "test-module-myapp" {} ''
  echo "Testing myapp module..."
  
  # Check file exists
  test -f ${../../modules/apps/myapp.nix} || {
    echo "FAIL: myapp.nix not found"
    exit 1
  }
  
  # Check for expected patterns
  ${pkgs.gnugrep}/bin/grep -q "programs.myapp" ${../../modules/apps/myapp.nix} || {
    echo "FAIL: myapp.nix missing programs.myapp config"
    exit 1
  }
  
  echo "✓ myapp module structure is valid"
  touch $out
'';
```

### Test Helpers

Signal provides helper functions for common integration test patterns:

#### `mkModuleTest` - Module Structure Validation

```nix
module-myapp-evaluates = mkModuleTest 
  "myapp"                          # Test name
  ../../modules/apps/myapp.nix     # Module path
  "myapp";                         # Program name to check
```

This automatically checks:
- File exists
- Contains `programs.myapp` configuration

#### `mkExampleTest` - Example Configuration Validation

```nix
integration-example-myconfig = mkExampleTest 
  "myconfig"                       # Test name
  ../../examples/myconfig.nix      # Example path
  "requiredPattern";               # Pattern that must exist
```

#### `mkThemeResolutionTest` - Theme Resolution Validation

```nix
validation-myapp-theme = mkThemeResolutionTest
  "myapp-resolution"               # Test name
  ../../modules/apps/myapp.nix     # Module path
  "resolveThemeMode"               # Pattern to check
  "myapp uses theme resolution";   # Description
```

### Manual Integration Test Structure

For more complex validation, write manual tests:

```nix
module-myapp-colors = pkgs.runCommand "test-module-myapp-colors" {} ''
  echo "Testing myapp color configuration..."
  
  ${assertFileExists ../../modules/apps/myapp.nix "myapp module"}
  
  # Check for color configuration sections
  ${assertFileContains ../../modules/apps/myapp.nix 
    "primary.background" 
    "myapp module missing primary background color"}
  
  ${assertFileContains ../../modules/apps/myapp.nix 
    "accent.primary" 
    "myapp module missing accent colors"}
  
  # Check for TOML generation (if applicable)
  ${assertFileContains ../../modules/apps/myapp.nix 
    "generators.toTOML" 
    "myapp module missing TOML generator"}
  
  echo "✓ myapp color configuration is valid"
  touch $out
'';
```

### Helper Functions Available

```nix
# Check file exists
assertFileExists = path: name: ''
  test -f ${path} || {
    echo "FAIL: ${name} not found"
    exit 1
  }
'';

# Check file contains pattern
assertFileContains = path: pattern: description: ''
  ${pkgs.gnugrep}/bin/grep -q "${pattern}" ${path} || {
    echo "FAIL: ${description}"
    exit 1
  }
'';
```

### Exporting Integration Tests

Export your integration test in `tests/default.nix`:

```nix
# tests/default.nix
{
  inherit (integrationTests)
    module-helix-dark
    module-gtk-evaluates
    module-myapp-evaluates  # Add your test here
    ;
}
```

### Integration Test Best Practices

1. **Clear Error Messages**: Tell the developer exactly what failed
2. **Test Structure First**: Verify files exist before checking content
3. **Use Helpers**: Leverage `mkModuleTest`, `mkExampleTest` for consistency
4. **Pattern Matching**: Use grep to verify configuration patterns
5. **Success Output**: Echo success message before `touch $out`

## Running Tests

### Run All Tests

```bash
# Run complete test suite
nix flake check

# With verbose output
nix flake check --print-build-logs
```

### Run Specific Test Categories

#### Unit Tests Only (Fast Development Loop)

```bash
# Run all pure unit tests (~5-10 seconds)
nix build .#checks.x86_64-linux.unit-lib-resolveThemeMode
nix build .#checks.x86_64-linux.unit-lib-getColors
nix build .#checks.x86_64-linux.accessibility-contrast-estimation
```

Benefits:
- Pure Nix evaluation (9 tests)
- ~0.5-1 second per test
- Ideal for TDD and rapid iteration

#### Integration Tests Only

```bash
# Run all integration tests (~30-60 seconds)
nix build .#checks.x86_64-linux.integration-example-basic
nix build .#checks.x86_64-linux.module-helix-dark
nix build .#checks.x86_64-linux.validation-theme-names
```

Benefits:
- Shell-based validation (15 tests)
- ~2-5 seconds per test
- Run before commits or in CI

### Run Specific Test

```bash
# Run single test
nix build .#checks.x86_64-linux.unit-lib-resolveThemeMode

# With verbose output
nix build .#checks.x86_64-linux.unit-lib-resolveThemeMode --print-build-logs

# With trace for debugging
nix build .#checks.x86_64-linux.unit-lib-resolveThemeMode --show-trace
```

### Using the Test Runner Script

The `run-tests.sh` script provides convenient test execution:

```bash
# Run all tests
./run-tests.sh --all

# Run specific test
./run-tests.sh unit-lib-resolveThemeMode

# Run test category
./run-tests.sh --category unit
./run-tests.sh --category integration

# List all available tests
./run-tests.sh --list

# Verbose output
./run-tests.sh --verbose unit-lib-getColors
```

### Development Workflow

**Recommended workflow for adding a new module:**

1. **Write the module code** in `modules/`
2. **Run unit tests** to verify library functions
   ```bash
   nix build .#checks.x86_64-linux.unit-lib-resolveThemeMode
   ```
3. **Add integration test** for module structure
4. **Run your integration test**
   ```bash
   nix build .#checks.x86_64-linux.module-myapp-evaluates
   ```
5. **Run all tests** before committing
   ```bash
   nix flake check
   ```

## Debugging Test Failures

### Understanding Test Output

#### Successful Test

```
✓ Test passed for lib-resolve-theme-mode
```

#### Failed Unit Test

```
FAIL: Tests failed for lib-resolve-theme-mode
[{"name":"testAutoToDark","expected":"dark","result":"light"}]
```

The JSON output shows:
- Which test case failed (`testAutoToDark`)
- What was expected (`"dark"`)
- What was actually returned (`"light"`)

#### Failed Integration Test

```
FAIL: helix module missing programs.helix config
error: builder for '.../test-module-helix.drv' failed
```

### Common Debugging Steps

#### 1. Use `--show-trace` for Evaluation Errors

```bash
nix build .#checks.x86_64-linux.unit-lib-resolveThemeMode --show-trace
```

This shows the full evaluation trace, helping identify:
- Infinite recursion
- Type errors
- Missing attributes
- Evaluation path that caused the error

#### 2. Use `--print-build-logs` for Build Errors

```bash
nix build .#checks.x86_64-linux.module-helix-dark --print-build-logs
```

This shows:
- Shell script output
- Grep failures
- File not found errors
- Full test execution log

#### 3. Check the Test Definition

Look at the test in `tests/unit/default.nix` or `tests/integration/default.nix`:

```bash
# View unit test
cat tests/unit/default.nix | grep -A 20 "unit-lib-resolveThemeMode"

# View integration test
cat tests/integration/default.nix | grep -A 20 "module-helix-dark"
```

#### 4. Test the Function Directly

For unit tests, evaluate the function in `nix repl`:

```bash
nix repl
:l flake.nix
signalLib = lib.evalModules { ... }
signalLib.resolveThemeMode "auto"
```

#### 5. Check File Paths

For integration tests, verify files exist:

```bash
ls -la modules/editors/helix.nix
cat modules/editors/helix.nix | grep "programs.helix"
```

### Common Errors and Solutions

#### Error: "File not found"

**Problem**: Module file doesn't exist at expected path

**Solution**:
```bash
# Check file exists
ls modules/apps/myapp.nix

# Verify path in test matches actual location
grep "myapp.nix" tests/integration/default.nix
```

#### Error: "Pattern not found"

**Problem**: grep pattern doesn't match file content

**Solution**:
```bash
# Check what's actually in the file
cat modules/apps/myapp.nix

# Test the grep pattern manually
grep "programs.myapp" modules/apps/myapp.nix

# Note: Escape special characters in patterns
# Wrong: grep "config.attr" file
# Right: grep "config\\.attr" file
```

#### Error: "Expected X but got Y"

**Problem**: Function returned unexpected value

**Solution**:
1. Check function implementation in `lib/default.nix`
2. Verify input data structure
3. Test with simpler inputs
4. Add debug output with `builtins.trace`

```nix
testMyFunction = {
  expr = 
    let
      input = "test";
      result = signalLib.myFunction input;
      _ = builtins.trace "Input: ${input}" null;
      _ = builtins.trace "Result: ${result}" null;
    in
      result;
  expected = "expected-value";
};
```

#### Error: "Infinite recursion"

**Problem**: Function calls itself without base case

**Solution**:
1. Check for circular imports
2. Verify function has base case
3. Review let-in bindings for self-reference
4. Use `--show-trace` to see recursion path

#### Error: "Attribute missing"

**Problem**: Accessing undefined attribute

**Solution**:
```nix
# Use hasAttr to check
testMyFunction = {
  expr = builtins.hasAttr "myAttr" mySet;
  expected = true;
};

# Use attrNames to debug
testMyFunction = {
  expr = builtins.attrNames mySet;
  expected = [ "attr1" "attr2" "myAttr" ];
};
```

## Test Requirements for New Modules

Every new application module **must include**:

### 1. Module Structure Test (Required)

Verify the module file exists and has basic structure:

```nix
module-myapp-evaluates = mkModuleTest 
  "myapp" 
  ../../modules/apps/myapp.nix 
  "myapp";
```

This ensures:
- ✅ Module file exists at correct path
- ✅ Contains `programs.myapp` configuration

### 2. Color Configuration Test (Recommended)

Verify color mappings are present:

```nix
module-myapp-colors = pkgs.runCommand "test-module-myapp-colors" {} ''
  echo "Testing myapp color configuration..."
  
  ${assertFileContains ../../modules/apps/myapp.nix 
    "accent.primary" 
    "myapp module missing accent colors"}
  
  ${assertFileContains ../../modules/apps/myapp.nix 
    "tonal.background" 
    "myapp module missing background colors"}
  
  echo "✓ myapp has required colors"
  touch $out
'';
```

### 3. Theme Resolution Test (For Tier 1-2 Modules)

Verify the module uses proper theme resolution:

```nix
validation-myapp-theme = mkThemeResolutionTest
  "myapp-resolution"
  ../../modules/apps/myapp.nix
  "resolveThemeMode"
  "myapp uses theme resolution";
```

### 4. Example Configuration Test (If Example Provided)

If you created an example configuration:

```nix
integration-example-myapp = mkExampleTest 
  "myapp-example" 
  ../../examples/myapp-config.nix 
  "programs.myapp";
```

### Test Coverage Checklist

When adding a new module, ensure:

- [ ] Module structure test exists
- [ ] Color configuration test exists (if applicable)
- [ ] Theme resolution test exists (for Tier 1-2)
- [ ] Example test exists (if example provided)
- [ ] All tests pass locally (`nix flake check`)
- [ ] Tests are exported in `tests/default.nix`
- [ ] Test names follow naming convention

### Minimum Test Requirements by Tier

**Tier 1 (Native Theme):**
- ✅ Module structure test
- ✅ Theme resolution test
- ✅ Color configuration test (optional but recommended)

**Tier 2 (Structured Colors):**
- ✅ Module structure test
- ✅ Color configuration test
- ✅ ANSI color mapping test (for terminals)

**Tier 3 (Freeform Settings):**
- ✅ Module structure test
- ✅ Settings generation test

**Tier 4 (Raw Config):**
- ✅ Module structure test
- ✅ Config file generation test
- ✅ File placement test

## Test Templates

### Template: Basic Module Structure Test

```nix
# tests/integration/default.nix

module-MYAPP-evaluates = pkgs.runCommand "test-module-MYAPP" {} ''
  echo "Testing MYAPP module..."
  
  test -f ${../../modules/CATEGORY/MYAPP.nix} || {
    echo "FAIL: MYAPP.nix not found"
    exit 1
  }
  
  ${pkgs.gnugrep}/bin/grep -q "programs.MYAPP" ${../../modules/CATEGORY/MYAPP.nix} || {
    echo "FAIL: MYAPP.nix missing programs.MYAPP config"
    exit 1
  }
  
  echo "✓ MYAPP module structure is valid"
  touch $out
'';
```

### Template: Color Configuration Test

```nix
# tests/integration/default.nix

module-MYAPP-colors = pkgs.runCommand "test-module-MYAPP-colors" {} ''
  echo "Testing MYAPP module color configuration..."
  
  # Check for Signal color usage
  ${assertFileContains ../../modules/CATEGORY/MYAPP.nix 
    "signalColors" 
    "MYAPP module missing signalColors"}
  
  # Check for specific color attributes
  ${assertFileContains ../../modules/CATEGORY/MYAPP.nix 
    "accent.primary" 
    "MYAPP module missing primary accent"}
  
  ${assertFileContains ../../modules/CATEGORY/MYAPP.nix 
    "tonal.background" 
    "MYAPP module missing background color"}
  
  echo "✓ MYAPP module has correct color configuration"
  touch $out
'';
```

### Template: Config File Generation Test

```nix
# tests/integration/default.nix

module-MYAPP-config-generation = pkgs.runCommand "test-module-MYAPP-config" {} ''
  echo "Testing MYAPP config file generation..."
  
  # Check for config file generation
  ${assertFileContains ../../modules/CATEGORY/MYAPP.nix 
    "xdg.configFile" 
    "MYAPP module missing xdg.configFile"}
  
  ${assertFileContains ../../modules/CATEGORY/MYAPP.nix 
    "MYAPP/config.TOML" 
    "MYAPP module missing config path"}
  
  # Check for TOML/JSON/YAML generator
  ${assertFileContains ../../modules/CATEGORY/MYAPP.nix 
    "generators.toTOML" 
    "MYAPP module missing TOML generator"}
  
  echo "✓ MYAPP config generation is valid"
  touch $out
'';
```

### Template: ANSI Colors Test (Terminals)

```nix
# tests/integration/default.nix

module-MYAPP-ansi-colors = pkgs.runCommand "test-module-MYAPP-ansi" {} ''
  echo "Testing MYAPP ANSI color configuration..."
  
  # Check for all 16 ANSI colors
  for i in {0..15}; do
    ${pkgs.gnugrep}/bin/grep -q "color$i" ${../../modules/terminals/MYAPP.nix} || {
      echo "FAIL: MYAPP missing color$i"
      exit 1
    }
  done
  
  # Check for foreground/background
  ${assertFileContains ../../modules/terminals/MYAPP.nix 
    "foreground" 
    "MYAPP missing foreground color"}
  
  ${assertFileContains ../../modules/terminals/MYAPP.nix 
    "background" 
    "MYAPP missing background color"}
  
  echo "✓ MYAPP ANSI colors are complete"
  touch $out
'';
```

## Common Testing Patterns

### Pattern: Testing Color Transformations

```nix
unit-color-transformation = mkTest "color-transformation" {
  testPreservesStructure = {
    expr = 
      let
        color = { l = 0.5; c = 0.1; h = 180.0; hex = "#808080"; };
        result = signalLib.colors.transformColor color;
      in
        builtins.hasAttr "l" result 
        && builtins.hasAttr "c" result 
        && builtins.hasAttr "h" result;
    expected = true;
  };
};
```

### Pattern: Testing Attribute Presence

```nix
unit-attribute-presence = mkTest "attribute-presence" {
  testHasRequiredAttrs = {
    expr = 
      let
        colors = signalLib.getColors "dark";
        hasAll = 
          builtins.hasAttr "tonal" colors &&
          builtins.hasAttr "accent" colors &&
          builtins.hasAttr "categorical" colors;
      in
        hasAll;
    expected = true;
  };
};
```

### Pattern: Testing Enum Values

```nix
unit-enum-validation = mkTest "enum-validation" {
  testValidMode = {
    expr = signalLib.isValidResolvedMode "dark";
    expected = true;
  };
  
  testInvalidMode = {
    expr = signalLib.isValidResolvedMode "invalid";
    expected = false;
  };
};
```

### Pattern: Testing Boundary Conditions

```nix
unit-boundary-conditions = mkTest "boundary-conditions" {
  testZeroValue = {
    expr = signalLib.myFunction 0;
    expected = "default";
  };
  
  testEmptyString = {
    expr = signalLib.myFunction "";
    expected = "empty";
  };
  
  testMaxValue = {
    expr = signalLib.myFunction 1.0;
    expected = "max";
  };
};
```

### Pattern: Testing File Patterns

```nix
integration-file-patterns = pkgs.runCommand "test-patterns" {} ''
  # Check for multiple patterns
  for pattern in "pattern1" "pattern2" "pattern3"; do
    ${pkgs.gnugrep}/bin/grep -q "$pattern" ${../../modules/myapp.nix} || {
      echo "FAIL: Missing $pattern"
      exit 1
    }
  done
  
  echo "✓ All patterns found"
  touch $out
'';
```

## Performance Considerations

### Test Execution Times

**Unit Tests:**
- Pure evaluation: ~0.5-1 second per test
- No disk I/O or shell commands
- Runs 10x faster than integration tests

**Integration Tests:**
- Shell execution: ~2-5 seconds per test
- File system access required
- Network access disabled

### Optimization Strategies

#### 1. Use Unit Tests When Possible

```nix
# Good: Fast unit test
unit-simple-check = mkTest "simple" {
  testValue = {
    expr = signalLib.getValue "key";
    expected = "value";
  };
};

# Avoid: Slow integration test for pure function
integration-simple-check = pkgs.runCommand "test" {} ''
  ${pkgs.nix}/bin/nix eval --expr '...'
'';
```

#### 2. Batch Integration Tests

```nix
# Good: Single test checking multiple patterns
module-myapp-complete = pkgs.runCommand "test-myapp" {} ''
  ${assertFileExists ../../modules/myapp.nix "module"}
  ${assertFileContains ../../modules/myapp.nix "pattern1" "check1"}
  ${assertFileContains ../../modules/myapp.nix "pattern2" "check2"}
  ${assertFileContains ../../modules/myapp.nix "pattern3" "check3"}
  touch $out
'';

# Avoid: Separate tests for each pattern
module-myapp-pattern1 = ...
module-myapp-pattern2 = ...
module-myapp-pattern3 = ...
```

#### 3. Run Targeted Tests During Development

```bash
# During development: Run only relevant tests
nix build .#checks.x86_64-linux.unit-lib-myFunction

# Before commit: Run all unit tests
nix build .#checks.x86_64-linux.unit-*

# Before push: Run full suite
nix flake check
```

### Performance Benchmarks

| Test Type | Count | Total Time | Avg/Test |
|-----------|-------|------------|----------|
| Unit Tests | 9 | ~9s | ~1s |
| Integration Tests | 15 | ~45s | ~3s |
| Static Checks | 4 | ~10s | ~2.5s |
| **Full Suite** | **30+** | **~6min** | **~10s** |

## CI/CD Integration

### GitHub Actions Workflow

Tests run automatically on:
- Push to `main` branch
- Pull requests
- Manual workflow dispatch

### CI Test Stages

1. **Smoke Tests** (2-3 min)
   - Format checks
   - Flake structure validation
   - Quick module evaluation

2. **Unit Tests** (1-2 min)
   - All pure Nix tests
   - Library function validation
   - Fast feedback on logic errors

3. **Integration Tests** (3-4 min)
   - Module structure validation
   - Example configuration checks
   - Full Home Manager evaluation

### CI Test Output

#### Success

```
✅ checks.x86_64-linux.unit-lib-resolveThemeMode
✅ checks.x86_64-linux.integration-example-basic
✅ checks.x86_64-linux.module-helix-dark
```

#### Failure

```
❌ checks.x86_64-linux.validation-theme-names
::error title=Test Failed (validation-theme-names)::Test failed after 3s
```

GitHub Actions annotations point directly to the failed test in the workflow logs.

### Viewing Test Results

1. **Pull Request Checks Tab** - See all test results
2. **Actions Tab** - View detailed logs
3. **Artifacts** - Download test logs (kept for 7 days)
4. **PR Comments** - Automated summary with failure details

### Local CI Simulation

Run the same checks as CI locally:

```bash
# Format check
nixfmt flake.nix modules/**/*.nix tests/**/*.nix

# Run all tests
nix flake check

# Run with same verbosity as CI
nix flake check --print-build-logs
```

## Additional Resources

### Related Documentation

- **[testing.md](testing.md)** - General testing overview
- **[CONTRIBUTING_APPLICATIONS.md](../CONTRIBUTING_APPLICATIONS.md)** - Module contribution guide
- **[tier-system.md](tier-system.md)** - Configuration tier reference
- **[design-principles.md](design-principles.md)** - Testing philosophy context

### Example Tests to Study

**Good Unit Test Examples:**
- `unit-lib-resolveThemeMode` - Simple input/output test
- `accessibility-contrast-estimation` - Multiple related test cases
- `color-manipulation-lightness` - Tests transformation preserves properties

**Good Integration Test Examples:**
- `module-helix-dark` - Clean module structure test
- `module-mpv-colors` - Comprehensive color configuration test
- `validation-theme-names` - Pattern consistency across files

### Getting Help

**If you're stuck:**

1. **Review existing tests** - Find similar tests in `tests/`
2. **Check documentation** - Read `docs/testing.md` and this guide
3. **Run with verbose output** - Use `--print-build-logs` and `--show-trace`
4. **Ask in Discussions** - Post your test code and error message
5. **Open Draft PR** - Get feedback on work in progress

**Common Questions:**

- **"Should I write unit or integration test?"** → See [decision tree](#when-to-use-each-test-type)
- **"How do I test file generation?"** → Use integration test with grep patterns
- **"Why is my test slow?"** → Check if it can be a unit test instead
- **"Test passes locally but fails in CI?"** → Check file paths and git tracking

## Summary

### Quick Reference

**Test Type Decision:**
- Pure function? → Unit test
- File validation? → Integration test
- Example config? → Integration test

**Required Tests for New Module:**
- ✅ Module structure test
- ✅ Color configuration test (if applicable)
- ✅ Theme resolution test (Tier 1-2)

**Running Tests:**
```bash
# Fast unit tests during development
nix build .#checks.x86_64-linux.unit-*

# Full test suite before commit
nix flake check
```

**Debugging:**
```bash
# See evaluation trace
nix build --show-trace

# See build logs
nix build --print-build-logs
```

### Next Steps

1. ✅ Read [CONTRIBUTING_APPLICATIONS.md](../CONTRIBUTING_APPLICATIONS.md)
2. ✅ Study example tests in `tests/unit/` and `tests/integration/`
3. ✅ Write tests for your new module
4. ✅ Run tests locally
5. ✅ Submit PR with passing tests

---

**Signal Design System** - Testing built on scientific principles.
