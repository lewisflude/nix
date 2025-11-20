# Linting Tool Configuration

This document explains how `statix` and `deadnix` are configured to work together harmoniously.

## Overview

Both `statix` and `deadnix` are excellent Nix linting tools, but they have different preferences that can conflict:

- **Statix** prefers `{ ... }:` over `{ }:` for empty function patterns
- **Deadnix** flags unused lambda arguments, including those in `{ ... }:` patterns
- **Home Manager modules** receive standard arguments (`system`, `pkgs`, `lib`, `config`) even if unused

## Configuration Strategy

### Statix Configuration (`statix.toml`)

Statix uses an ignore list for files that legitimately use empty or ellipsis patterns:

```toml
ignore = [
  # System and palette files
  "**/systems.nix",
  "**/palette.nix",

  # Home Manager modules that don't use standard args
  "**/video-conferencing.nix",
  "**/keyboard.nix",
]
```

**Rationale**: These files use `{ ... }:` to accept any arguments from the module system, which is the idiomatic Nix pattern for Home Manager modules that don't need specific arguments.

### Deadnix Configuration (`.deadnix.toml`)

Deadnix is configured at the project root to ignore unused lambda arguments:

```toml
# Ignore unused lambda arguments
# This allows { ... } patterns which statix prefers
no_lambda_arg = true
```

**Rationale**: This allows modules to use `{ ... }:` patterns (preferred by statix) without deadnix complaining about unused arguments.

## Best Practices

### When to Use `{ ... }:` vs Explicit Arguments

1. **Use `{ ... }:` when**:
   - The module doesn't use any standard arguments
   - The module is a simple configuration that just sets options
   - You want to accept any arguments for future extensibility

2. **Use explicit arguments when**:
   - The module actually uses specific arguments
   - You want to make dependencies explicit
   - The module needs type checking on arguments

### Example: Minimal Home Manager Module

```nix
# ✅ Good: Uses { ... } for minimal config
{ ... }:
{
  home.packages = [
    # Simple package list, no args needed
  ];
}
```

### Example: Module Using Arguments

```nix
# ✅ Good: Explicitly lists used arguments
{ pkgs, lib, ... }:
{
  home.packages = [
    pkgs.curl
    pkgs.wget
  ];

  # Uses lib for something
  programs.git.enable = lib.mkDefault true;
}
```

## Configuration Files

- **`statix.toml`**: Project root - Statix ignore patterns
- **`.deadnix.toml`**: Project root - Deadnix global configuration
- **`home/common/_sources/.deadnix.toml`**: Per-directory override for generated files

## Pre-commit Integration

Both tools are integrated via pre-commit hooks in `lib/output-builders.nix`:

```nix
deadnix = {
  enable = true;
  # Configuration is in .deadnix.toml at project root
};

statix = {
  enable = true;
  entry = "${pkgs.statix}/bin/statix check --format errfmt";
  # Ignores are configured in statix.toml
};
```

## Troubleshooting

### Statix complains about empty patterns

Add the file to `statix.toml` ignore list if it legitimately uses `{ ... }:` or `{ }:` patterns.

### Deadnix complains about unused arguments

1. If using `{ ... }:`, ensure `.deadnix.toml` has `no_lambda_arg = true`
2. If using explicit args, remove unused ones
3. For generated files, add a `.deadnix.toml` in that directory

### Both tools conflict

The current configuration should handle most cases. If you encounter conflicts:

1. Check if the file should be in `statix.toml` ignore list
2. Verify `.deadnix.toml` configuration is correct
3. Consider if the function signature can be improved

## References

- [Statix Documentation](https://github.com/nerdypepper/statix)
- [Deadnix Documentation](https://github.com/astro/deadnix)
- [Nix Function Patterns](https://nixos.org/manual/nix/stable/language/constructs.html#functions)
