# Analyzing System Size

## Quick Analysis (Run on NixOS)

```bash
# Get total system closure size
nix path-info -rS /run/current-system | awk '{sum+=$1} END {printf "%.2f GB\n", sum/1024/1024/1024}'

# Top 30 largest packages
nix path-info -rS /run/current-system | sort -rn | head -30 | \
  awk '{printf "%.2f GB\t%s\n", $1/1024/1024/1024, $2}'
```

## Using the Analysis Script

I've created a dedicated script for this:

```bash
# Show top 30 largest packages (default)
nix run .#analyze-system-size

# Show top 50 packages
nix run .#analyze-system-size -- --top 50

# Show only packages >= 100MB
nix run .#analyze-system-size -- --min_size 100

# Combined: top 50 packages >= 100MB
nix run .#analyze-system-size -- --top 50 --min_size 100
```

## What to Look For

Based on your configuration, the largest dependencies are likely:

### Expected Large Packages

1. **32-bit libraries** (~4-6GB) - If `enable32Bit = true`
   - `mesa-32bit`, `glibc-32bit`, `nvidia-x11-32bit`, etc.

2. **Steam & Gaming** (~5-10GB)
   - `steam`, `steam-run`, `proton`, `wine`, `gamescope`

3. **Development Toolchains** (~3-5GB) - If still enabled globally
   - `rustc`, `rust-analyzer`, `python`, `nodejs`, `llvm`, `clang`

4. **Home Assistant** (~2-4GB)
   - `home-assistant` and all its Python dependencies

5. **Media Management** (~3-5GB)
   - `jellyfin`, `jellyseerr`, `ollama`, etc.

6. **NVIDIA Drivers** (~1-2GB)
   - `nvidia-x11`, `nvidia-vaapi-driver`, etc.

7. **Linux Firmware** (~500MB-1GB)
   - `linux-firmware`

8. **Chromium** (~500MB)
   - `chromium-unwrapped`

## After Your Changes

After removing LibreOffice, moving dev toolchains to devShells, and removing Home Assistant components, you should see:

- ? No `libreoffice` in top packages
- ? No `rustc`, `python`, `nodejs` in top packages (if moved to devShells)
- ? Smaller `home-assistant` (without music_assistant, zha, home-llm)

## Next Steps

1. **Rebuild your system**: `nh os switch`
2. **Run the analysis**: `nix run .#analyze-system-size`
3. **Review the results** and identify what else can be removed
4. **Consider disabling 32-bit** if you only play modern games: ~4-6GB savings
