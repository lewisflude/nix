# Git Hooks

This directory contains Git hooks to help maintain code quality.

## Available Hooks

### pre-commit
Validates Nix syntax before allowing commits. This catches syntax errors like the `|}:` typo before they reach CI or production.

**What it checks:**
- Nix syntax validity with `nix-instantiate --parse`
- Code formatting (optional warning)

**How it works:**
- Runs automatically before each commit
- Only checks staged `.nix` files
- Blocks commit if syntax errors are found

### commit-msg
Validates commit messages follow Conventional Commits format.

**Format required:**
```
<type>: <description>

Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
```

## Setup

Configure Git to use these hooks:

```bash
git config core.hooksPath .githooks
```

This only needs to be done once per clone.

## Testing Hooks Manually

Test the pre-commit hook:
```bash
.githooks/pre-commit
```

Test the commit-msg hook:
```bash
echo "feat: test message" | .githooks/commit-msg -
```

## Bypassing Hooks (Emergency Use Only)

If you absolutely must bypass the hooks:
```bash
git commit --no-verify -m "emergency fix"
```

**⚠️ Use sparingly** - bypassing hooks defeats their purpose and can introduce bugs.

## Hook Benefits

1. **Catch errors early** - Before they reach CI or production
2. **Fast feedback** - Instant validation on your machine
3. **Save CI time** - Don't waste CI minutes on syntax errors
4. **Cleaner history** - Enforce commit message standards
5. **Better collaboration** - Consistent code quality across contributors

## Troubleshooting

### Hook not running
```bash
# Check hook is executable
ls -la .githooks/pre-commit

# Make it executable if needed
chmod +x .githooks/pre-commit

# Verify Git is configured to use hooks
git config core.hooksPath
# Should output: .githooks
```

### False positives
If the hook flags valid Nix code as invalid, this may be a `nix-instantiate` issue. Check your Nix installation:
```bash
nix --version
nix-instantiate --version
```

### Hook too slow
If checking many files is slow, you can temporarily disable formatting checks by commenting out the optional formatter section in `.githooks/pre-commit`.
