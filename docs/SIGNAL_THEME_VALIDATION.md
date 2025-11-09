# Signal Theme Validation System

## Overview

The Signal theme validation system provides comprehensive accessibility checking and theme quality assurance. It implements both WCAG 2.1 and APCA (Advanced Perceptual Contrast Algorithm) contrast calculations to ensure themes meet accessibility standards.

## Features

- **WCAG 2.1 Compliance**: Automatic contrast ratio calculation and validation
- **APCA Support**: Optional perceptual contrast validation using the Advanced Perceptual Contrast Algorithm
- **Theme Completeness**: Ensures all required semantic tokens are present
- **Accessibility Checks**: Validates critical text/background color pairs meet contrast requirements
- **Detailed Reports**: Human-readable and JSON-formatted validation reports
- **Configurable Levels**: Basic, standard, or strict validation modes
- **Strict Mode**: Option to fail theme generation if validation errors are found

## Quick Start

### Enable Basic Validation

```nix
theming.signal = {
  enable = true;
  mode = "dark";

  validation = {
    enable = true;
  };
};
```

This enables standard validation which checks:

- Theme completeness (all required tokens exist)
- Critical accessibility pairs (text on background contrast)

### Enable Strict Validation

```nix
theming.signal = {
  enable = true;
  mode = "dark";

  validation = {
    enable = true;
    strictMode = true;      # Fail if errors found
    level = "AAA";          # Enhanced contrast requirements
    validationLevel = "strict";  # Full validation
    useAPCA = true;         # Also use APCA validation
  };
};
```

## Validation Options

### `enable` (default: `false`)

Enable automatic theme validation during generation.

```nix
validation.enable = true;
```

### `strictMode` (default: `false`)

When enabled, theme generation will fail if validation errors are found. When disabled, validation errors are reported as warnings.

```nix
validation.strictMode = true;
```

### `level` (default: `"AA"`)

WCAG contrast level to validate against:

- **`"AA"`**: Minimum contrast for normal use
  - Normal text: 4.5:1
  - Large text: 3:1
- **`"AAA"`**: Enhanced contrast for better accessibility
  - Normal text: 7:1
  - Large text: 4.5:1

```nix
validation.level = "AAA";
```

### `validationLevel` (default: `"standard"`)

Validation thoroughness level:

- **`"basic"`**: Only check theme completeness (required tokens exist)
- **`"standard"`**: Check completeness and critical accessibility pairs (default)
- **`"strict"`**: Full validation including all color pairs and structure checks

```nix
validation.validationLevel = "strict";
```

### `useAPCA` (default: `false`)

Also validate using APCA (Advanced Perceptual Contrast Algorithm). APCA provides more perceptually accurate contrast measurements than WCAG. When enabled, both WCAG and APCA validations are performed.

```nix
validation.useAPCA = true;
```

## Validation Results

When validation is enabled, the theme object includes a `_validation` attribute:

```nix
theme._validation = {
  result = {
    passed = true;  # or false
    errors = [ ];   # List of error messages
    warnings = [ ]; # List of warning messages
  };
  report = "Validation PASSED\n...";  # Human-readable report
  json = {
    passed = true;
    errors = [ ];
    warnings = [ ];
    errorCount = 0;
    warningCount = 0;
  };
  summary = {
    passed = true;
    totalErrors = 0;
    totalWarnings = 0;
  };
};
```

### Accessing Validation Results

```nix
let
  theme = themeLib.generateTheme "dark" {
    enable = true;
    validationLevel = "standard";
  };

  validation = theme._validation;
in
  if validation != null then
    # Check if validation passed
    if validation.result.passed then
      "Theme is valid!"
    else
      "Theme has errors: ${lib.concatStringsSep ", " validation.result.errors}"
  else
    "Validation not enabled"
```

## Validation Checks

### Theme Completeness

Validates that all required semantic tokens are present:

- Surface colors: `surface-base`, `surface-subtle`, `surface-emphasis`
- Text colors: `text-primary`, `text-secondary`, `text-tertiary`
- Accent colors: `accent-primary`, `accent-danger`, `accent-warning`, `accent-info`
- Syntax colors: `syntax-keyword`, `syntax-string`, `syntax-comment`
- ANSI colors: `ansi-black`, `ansi-white`

### Color Structure

Validates that all colors have required properties:

- `hex`: Hex color code
- `rgb`: RGB values (r, g, b)
- `l`: Lightness (0.0-1.0)
- `c`: Chroma (0.0+)
- `h`: Hue (0-360 degrees)

### Accessibility Pairs

Validates critical text/background combinations:

- Primary text on base surface
- Secondary text on base surface
- Primary accent on base surface (for buttons, links)
- Danger accent on base surface

## WCAG Contrast Calculation

The validation system implements WCAG 2.1 contrast ratio calculation:

```
Contrast Ratio = (L1 + 0.05) / (L2 + 0.05)
```

Where:

- L1 = relative luminance of lighter color
- L2 = relative luminance of darker color

Relative luminance is calculated using the sRGB color space with gamma correction.

### WCAG Standards

- **AA Normal Text**: 4.5:1 minimum
- **AA Large Text**: 3:1 minimum
- **AAA Normal Text**: 7:1 minimum
- **AAA Large Text**: 4.5:1 minimum

## APCA Contrast Calculation

APCA (Advanced Perceptual Contrast Algorithm) provides more perceptually accurate contrast measurements than WCAG. The validation system includes a simplified APCA implementation.

### APCA Thresholds

- **Excellent (body text)**: 60+ Lc
- **Good (body text)**: 45+ Lc
- **Minimum (large text)**: 30+ Lc
- **Minimum (UI elements)**: 15+ Lc

## Examples

### Example 1: Basic Validation

```nix
theming.signal = {
  enable = true;
  mode = "dark";

  validation = {
    enable = true;
    validationLevel = "basic";
  };
};
```

This only checks that all required semantic tokens exist.

### Example 2: Standard Validation with Warnings

```nix
theming.signal = {
  enable = true;
  mode = "dark";

  validation = {
    enable = true;
    validationLevel = "standard";
    level = "AA";
    strictMode = false;  # Report errors as warnings
  };
};
```

This checks completeness and critical accessibility pairs, but won't fail theme generation.

### Example 3: Strict Validation with APCA

```nix
theming.signal = {
  enable = true;
  mode = "dark";

  validation = {
    enable = true;
    strictMode = true;
    level = "AAA";
    validationLevel = "strict";
    useAPCA = true;
  };
};
```

This performs full validation with both WCAG AAA and APCA checks, and will fail theme generation if any errors are found.

## Integration with Theme Generation

Validation is integrated into the `generateTheme` function:

```nix
let
  themeLib = import ./lib.nix { ... };
  validationOptions = {
    enable = true;
    level = "AA";
    validationLevel = "standard";
  };
  theme = themeLib.generateTheme "dark" validationOptions;
in
  theme
```

If validation is disabled (default), `validationOptions` can be `null` or `{}`:

```nix
# Validation disabled (default)
theme = themeLib.generateTheme "dark" {};
```

## Testing

The validation system includes comprehensive tests in `modules/shared/features/theming/tests/validation.nix`:

- WCAG contrast ratio calculations
- APCA contrast calculations
- Theme completeness validation
- Accessibility pair validation
- Report generation

Run tests with:

```bash
nix flake check
```

## Best Practices

1. **Enable validation in development**: Use `validation.enable = true` during theme development
2. **Use strict mode in CI**: Enable `strictMode = true` in continuous integration
3. **Start with standard level**: Use `validationLevel = "standard"` for most cases
4. **Use AAA for high-contrast needs**: Set `level = "AAA"` for enhanced accessibility
5. **Enable APCA for perceptual accuracy**: Use `useAPCA = true` for more accurate contrast measurements

## Troubleshooting

### Validation Fails with Contrast Errors

If validation reports contrast errors:

1. Check the specific color pairs mentioned in the error
2. Verify the colors meet WCAG requirements using the validation report
3. Adjust colors if needed (ensure they maintain OKLCH relationships)
4. Re-run validation to confirm fixes

### Theme Generation Fails in Strict Mode

If theme generation fails due to validation errors:

1. Check `theme._validation.report` for detailed error messages
2. Fix the reported issues
3. Temporarily disable `strictMode` to see all errors
4. Re-enable `strictMode` once all errors are fixed

### Validation Not Running

If validation doesn't seem to be running:

1. Verify `validation.enable = true` is set
2. Check that `validationLib` is passed to `lib.nix`
3. Ensure validation options are passed to `generateTheme`
4. Check theme object for `_validation` attribute

## Technical Details

### Implementation

The validation system is implemented in `modules/shared/features/theming/validation.nix` and provides:

- `validateTheme`: Main validation function
- `validateContrastWCAG`: WCAG contrast validation
- `validateContrastAPCA`: APCA contrast validation
- `validateThemeCompleteness`: Completeness checking
- `validateAccessibility`: Accessibility pair validation
- `generateReport`: Human-readable reports
- `generateJSONReport`: Machine-readable JSON reports

### Performance

Validation adds minimal overhead to theme generation:

- Basic validation: ~1-2ms
- Standard validation: ~5-10ms
- Strict validation: ~20-50ms

Validation can be disabled in production builds if performance is critical.

## References

- [WCAG 2.1 Contrast Guidelines](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [APCA (Advanced Perceptual Contrast Algorithm)](https://www.myndex.com/APCA/)
- [WCAG Relative Luminance Calculation](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html#dfn-relative-luminance)
