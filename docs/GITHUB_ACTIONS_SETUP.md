# GitHub Actions CI Setup

This guide helps you set up GitHub Actions for continuous integration with Cachix caching.

## ?? Quick Setup

### 1. Add Cachix Secret

1. Go to your repository: `https://github.com/lewisflude/nix-config/settings/secrets/actions`
2. Click **"New repository secret"**
3. Add:
   - **Name**: `CACHIX_AUTH_TOKEN`
   - **Secret**: Your Cachix auth token from [https://app.cachix.org/personal-auth-tokens](https://app.cachix.org/personal-auth-tokens)

### 2. Verify Workflow

The workflow file is already created at `.github/workflows/ci.yml`. It will automatically:

- ? Run on every push and pull request
- ? Run checks and tests
- ? Build NixOS configurations
- ? Build Darwin configurations (macOS)
- ? Cache all outputs using devour-flake (on main branch)

### 3. Test It

Push a commit and check the Actions tab:

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add GitHub Actions workflow with Cachix"
git push
```

Then visit: `https://github.com/lewisflude/nix-config/actions`

---

## ?? What the Workflow Does

### Job 1: Checks and Tests

- Runs `nix flake check`
- Runs pre-commit checks
- Validates all flake outputs

### Job 2: Build NixOS Configurations

- Builds all NixOS system configurations
- Uses Cachix for caching
- Runs on Linux runners

### Job 3: Build Darwin Configurations

- Builds all macOS (Darwin) configurations
- Uses Cachix for caching
- Runs on macOS runners

### Job 4: Cache All Outputs

- Uses devour-flake to build everything efficiently
- Caches all outputs to Cachix
- Only runs on main branch (to save CI minutes)
- Also caches flake inputs

---

## ?? Configuration

### Workflow Triggers

The workflow runs on:

- **Pull requests** - Validates changes
- **Pushes to main** - Full build + cache
- **Manual trigger** - Via "Run workflow" button

### Caching Strategy

- **On PRs**: Builds and tests, but doesn't cache (saves minutes)
- **On main**: Builds, tests, AND caches everything
- **Manual**: Full build + cache

### Customization

To modify the workflow, edit `.github/workflows/ci.yml`:

```yaml
# Change cache job to run on PRs too
cache-all:
  if: github.event_name == 'workflow_dispatch'  # Remove this line
```

---

## ?? Monitoring

### View Workflow Runs

Visit: `https://github.com/lewisflude/nix-config/actions`

### Check Cachix Cache

Visit: `https://app.cachix.org/cache/lewisflude`

### CI Badge

Your README already has a CI badge that will show status:

```markdown
[![CI](https://github.com/lewisflude/nix-config/workflows/CI/badge.svg)](https://github.com/lewisflude/nix-config/actions/workflows/ci.yml)
```

---

## ?? Troubleshooting

### Workflow Fails: "CACHIX_AUTH_TOKEN not found"

**Solution**: Add the secret as described in step 1 above.

### Workflow Fails: "Cache push failed"

**Possible causes**:

- Invalid auth token
- Cache name mismatch (should be `lewisflude`)
- Network issues

**Solution**:

1. Verify token at [Cachix](https://app.cachix.org/personal-auth-tokens)
2. Check cache name matches exactly
3. Re-run the workflow

### Builds are Slow

**First run**: Always slow (no cache yet)

**Subsequent runs**: Should be much faster (10-30x speedup)

**If still slow**:

- Check Cachix dashboard for cache hit rate
- Verify cache is being used (look for "copying path from '<https://lewisflude.cachix.org>'")
- Check network connectivity in workflow logs

### Darwin Build Fails

**Common issue**: macOS runners have limited resources

**Solution**:

- The workflow uses `--no-link` to avoid storing results
- Consider skipping Darwin builds on PRs if needed
- Or use conditional builds based on changed files

---

## ?? Tips

1. **First run will be slow** - This is normal, subsequent runs use cache
2. **Monitor cache usage** - Check Cachix dashboard regularly
3. **Adjust as needed** - Modify workflow based on your needs
4. **Use manual trigger** - Test workflow changes before merging

---

## ?? Related Documentation

- [Cachix Automation Strategy](./CACHIX_AUTOMATION_STRATEGY.md) - When to auto-run caching
- [Cachix Setup Guide](./CACHIX_FLAKEHUB_SETUP.md) - Initial Cachix setup
- [Nix CI Docs](https://nixos.org/manual/nix/stable/contributing/hacking.html#continuous-integration-with-github-actions) - Official Nix CI guide

---

## ? Success Indicators

You'll know it's working when:

- ? Workflow runs appear in Actions tab
- ? Checks pass (green checkmarks)
- ? Builds complete successfully
- ? Cache job pushes to Cachix (on main branch)
- ? Subsequent runs are much faster
- ? CI badge shows green status
