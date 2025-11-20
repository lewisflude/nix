# Continuous Integration

This repository uses GitHub Actions for continuous integration to ensure code quality and
prevent regressions.

## Workflows

### CI Workflow (`.github/workflows/ci.yml`)

The main CI workflow runs on:

- Pushes to `main` branch
- Pushes to any `claude/**` branch
- All pull requests
- Manual workflow dispatch

The workflow includes three jobs:

#### 1. Flake Check

Validates the entire Nix flake configuration:

```bash
nix flake check --show-trace --print-build-logs
```

This ensures:

- All flake outputs are valid
- No evaluation errors in configurations
- All checks defined in the flake pass

#### 2. Formatting

Verifies code formatting using treefmt:

```bash
nix fmt -- --fail-on-change
```

This checks:

- Nix files formatted with nixfmt-rfc-style
- YAML/Markdown formatted with prettier
- Shell scripts formatted with shfmt

**Fix locally:** Run `nix fmt` or `treefmt` to format all files.

#### 3. Build Configurations

Tests that the flake can be evaluated and basic operations work:

- Evaluates all system configurations
- Tests that the development shell can be entered

## Caching

The workflow uses
[DeterminateSystems' magic-nix-cache](https://github.com/DeterminateSystems/magic-nix-cache-action)
for automatic, zero-configuration caching of Nix builds. This significantly speeds up CI runs
by caching:

- Downloaded dependencies
- Build outputs
- Evaluation results

## Running Checks Locally

Before pushing, you can run the same checks locally:

```bash
# Run all flake checks
nix flake check

# Check formatting
nix fmt -- --fail-on-change

# Or fix formatting
nix fmt

# Enter dev shell to test
nix develop
```

## Dependabot

Dependabot is configured (`.github/dependabot.yml`) to automatically keep GitHub Actions
up to date with weekly checks.

## Best Practices

The CI configuration follows these best practices:

1. **Modern tooling**: Uses DeterminateSystems' actions for fast, reliable Nix installation
2. **Automatic caching**: Zero-configuration caching with magic-nix-cache
3. **Concurrency control**: Cancels in-progress runs on the same branch to save resources
4. **Minimal dependencies**: No external caching service required
5. **Fast feedback**: Parallel jobs for quick CI results

## Troubleshooting

### Flake Check Failures

If `nix flake check` fails:

1. Run locally with `nix flake check --show-trace` to see the full error
2. Check for evaluation errors in your Nix expressions
3. Ensure all hosts and configurations are valid

### Formatting Failures

If formatting checks fail:

1. Run `nix fmt` locally to fix formatting
2. Commit the formatted changes
3. The CI will pass on the next run

### Build Failures

If builds fail:

1. Ensure your changes work locally first
2. Check that all required inputs are available
3. Review the build logs in the GitHub Actions output
