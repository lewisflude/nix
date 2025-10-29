# Cachix & FlakeHub Setup Guide

This guide will help you set up both Cachix (binary cache) and FlakeHub (flake publishing) for your NixOS configuration.

## 🗄️ Part 1: Cachix Setup

### What You'll Gain
- **Faster local rebuilds**: Download pre-built packages instead of compiling (10-30 seconds vs 10-20 minutes)
- **Faster CI**: GitHub Actions will use cached builds
- **Multi-machine sync**: Share builds between jupiter and MacBook

### Step-by-Step Setup

#### 1. Create Cachix Account & Cache

1. Visit [cachix.org](https://app.cachix.org/)
2. Sign up using GitHub (easiest option)
3. Click **"Create binary cache"**
   - **Name**: `lewisflude-nix` (or your preferred name)
   - **Visibility**: Public (free tier, 5GB storage)
   - Click **Create**

#### 2. Get Your Credentials

After creating your cache:

1. Click on your cache name (`lewisflude-nix`)
2. Go to the **"Settings"** tab
3. Copy these three pieces of information:

```
Cache Name: lewisflude-nix
Auth Token: eyJhbG... (long token - keep this secret!)
Public Key: lewisflude-nix.cachix.org-1:XXXX... (for verifying downloads)
```

**⚠️ Important**: The Auth Token is secret - don't commit it to git!

#### 3. Add GitHub Secrets

1. Go to: `https://github.com/lewisflude/nix/settings/secrets/actions`
2. Click **"New repository secret"**
3. Add two secrets:

**Secret 1:**
```
Name: CACHIX_CACHE_NAME
Secret: lewisflude-nix
```

**Secret 2:**
```
Name: CACHIX_AUTH_TOKEN
Secret: (paste your auth token from Cachix)
```

#### 4. Update flake.nix

Open `flake.nix` and replace the placeholder comments with your cache:

```nix
extra-substituters = [
  "https://nix-community.cachix.org"
  # ... other caches ...
  "https://lewisflude-nix.cachix.org"  # ← Add your cache here
];

extra-trusted-public-keys = [
  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  # ... other keys ...
  "lewisflude-nix.cachix.org-1:YOUR_PUBLIC_KEY_HERE"  # ← Add your public key
];
```

Replace:
- `lewisflude-nix` with your cache name
- `YOUR_PUBLIC_KEY_HERE` with the public key from Cachix settings

#### 5. Test It Out

After updating `flake.nix`:

```bash
# Commit and push the changes
git add flake.nix docs/CACHIX_FLAKEHUB_SETUP.md
git commit -m "feat(cache): add personal Cachix cache"
git push

# Trigger the cache workflow manually on GitHub:
# Go to: Actions → "Build and Cache" → Run workflow

# Or enable auto-caching by uncommenting the triggers in .github/workflows/cachix.yml
```

#### 6. Verify It's Working

On your next rebuild:

```bash
# You should see downloads from your cache:
nh os switch  # or: darwin-rebuild switch --flake .

# Look for lines like:
# copying path '/nix/store/...' from 'https://lewisflude-nix.cachix.org'...
```

---

## 📦 Part 2: FlakeHub Setup

### What You'll Gain
- **Discoverable config**: Others can find and use your config as a template
- **Versioned releases**: Semantic versioning for your NixOS config
- **Better URLs**: Use `flakehub.com/f/lewisflude/nix/*` instead of GitHub URLs
- **Portfolio piece**: Show off your Nix skills

### Step-by-Step Setup

#### 1. Verify GitHub Permissions

FlakeHub uses GitHub's OIDC tokens (no extra secrets needed!). Your workflow is already configured.

Check your workflow file: `.github/workflows/flakehub-publish-tagged.yml`

It should have:
```yaml
permissions:
  id-token: "write"
  contents: "read"
```

✅ This is already set up in your config!

#### 2. Create Your First Release

When you're ready to publish your config:

```bash
# Make sure your config is in a good state
nh os switch --dry-run  # Test it works

# Create a git tag (use semantic versioning)
git tag -a v1.0.0 -m "feat: initial public release of NixOS configuration"

# Push the tag
git push origin v1.0.0
```

#### 3. Watch It Publish

1. Go to: `https://github.com/lewisflude/nix/actions`
2. You'll see "Publish tags to FlakeHub" running
3. After ~2 minutes, your flake will be live at:
   - `https://flakehub.com/flake/lewisflude/nix`

#### 4. Update Your README

Add to your README.md:

```markdown
## Using This Configuration

### With FlakeHub

```nix
{
  inputs.lewisflude-nix.url = "https://flakehub.com/f/lewisflude/nix/*";
}
```

### With GitHub

```nix
{
  inputs.lewisflude-nix.url = "github:lewisflude/nix";
}
```

### Available Versions

See all versions at: https://flakehub.com/flake/lewisflude/nix
```

---

## 🎯 Usage After Setup

### Cachix: Daily Use

**On new machines:**
```bash
cachix use lewisflude-nix
```

**Manual cache update:**
```bash
# Go to GitHub Actions → "Build and Cache" → Run workflow
```

**Check cache status:**
```bash
# Visit: https://app.cachix.org/cache/lewisflude-nix
```

### FlakeHub: Publishing New Versions

**Patch release (bug fixes):**
```bash
git tag v1.0.1
git push origin v1.0.1
```

**Minor release (new features):**
```bash
git tag v1.1.0
git push origin v1.1.0
```

**Major release (breaking changes):**
```bash
git tag v2.0.0
git push origin v2.0.0
```

---

## 🔧 Optional: Enable Auto-Caching

To automatically cache builds on every push to main:

Edit `.github/workflows/cachix.yml`:

```yaml
on:
  push:
    branches: [main]  # Add this
  workflow_dispatch:   # Keep manual option too
```

⚠️ **Note**: This will consume GitHub Actions minutes (but it's usually worth it!)

---

## 📊 Monitoring

### Cachix Dashboard
- View cache size, hit rates, downloads
- URL: `https://app.cachix.org/cache/lewisflude-nix`

### FlakeHub Dashboard
- View downloads, versions, stars
- URL: `https://flakehub.com/flake/lewisflude/nix`

---

## 🐛 Troubleshooting

### Cachix: "Failed to push"
- Check your `CACHIX_AUTH_TOKEN` is correct in GitHub secrets
- Verify cache name matches exactly

### Cachix: Not downloading from cache
- Check public key is correct in `flake.nix`
- Run `nix flake metadata` to verify cache is listed

### FlakeHub: Workflow fails
- Check the workflow run logs
- Ensure tag follows format: `v1.2.3` (v prefix + semver)
- Verify repo visibility is Public (required for FlakeHub)

### FlakeHub: Can't find published flake
- Wait 2-5 minutes after workflow completes
- Check: `https://flakehub.com/flake/lewisflude/nix`
- Ensure workflow completed successfully

---

## 📚 Next Steps

After setup:

1. **Cachix**:
   - Run the workflow manually to do your first cache
   - Rebuild a system and watch it use the cache
   - Consider enabling auto-cache on push

2. **FlakeHub**:
   - Clean up your README with usage instructions
   - Tag v1.0.0 when ready to share
   - Share your flake with the community!

3. **Documentation**:
   - Add a CHANGELOG.md for version history
   - Document your config features
   - Add screenshots or examples

---

## 🎉 Success Indicators

You'll know everything is working when:

✅ **Cachix**:
- Rebuilds take seconds instead of minutes
- You see "copying path from 'https://lewisflude-nix.cachix.org'"
- CI runs complete in 2-5 minutes

✅ **FlakeHub**:
- Your flake appears at flakehub.com/flake/lewisflude/nix
- Others can use your config as a template
- You can use cleaner URLs in documentation

---

Need help? Check the official docs:
- Cachix: https://docs.cachix.org/
- FlakeHub: https://flakehub.com/docs
