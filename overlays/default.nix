# Package overlays
# Simplified - only essential customizations
{ inputs, system }:
let
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";
in
{
  # Local custom packages
  localPkgs = _final: prev: {
    cursor = prev.callPackage (../pkgs + "/cursor") { };
  };

  # Custom NPM packages
  npm-packages = import ./npm-packages.nix;

  # Nix helper tool overlay
  nh =
    if inputs ? nh && inputs.nh ? overlays then inputs.nh.overlays.default else (_final: _prev: { });

  # Network topology visualization
  nix-topology =
    if inputs ? nix-topology && inputs.nix-topology ? overlays then
      inputs.nix-topology.overlays.default
    else
      (_final: _prev: { });

  # Use stable zed-editor from nixpkgs
  flake-editors = _final: prev: {
    inherit (prev) zed-editor;
  };

  # Rust toolchains from fenix (better than nixpkgs)
  fenix-overlay =
    if inputs ? fenix && inputs.fenix ? overlays then
      inputs.fenix.overlays.default
    else
      (_final: _prev: { });

  # Lazygit from flake input
  flake-git-tools =
    _final: prev:
    if inputs ? lazygit && inputs.lazygit ? packages && inputs.lazygit.packages ? ${system} then
      { lazygit = inputs.lazygit.packages.${system}.default; }
    else
      { inherit (prev) lazygit; };

  # Atuin from flake input
  flake-cli-tools =
    _final: prev:
    if inputs ? atuin && inputs.atuin ? packages && inputs.atuin.packages ? ${system} then
      { atuin = inputs.atuin.packages.${system}.default; }
    else
      { inherit (prev) atuin; };

  # Niri compositor (Linux only)
  niri =
    if isLinux && inputs ? niri && inputs.niri ? overlays then
      inputs.niri.overlays.niri
    else
      (_final: _prev: { });

  # Optimization: Disable direnv tests that fail on Darwin
  direnv-optimization = _final: prev: {
    direnv = prev.direnv.overrideAttrs (_old: {
      doCheck = false;
    });
  };

  # MCP servers overlay (version-pinned server implementations)
  mcps =
    if inputs ? mcps && inputs.mcps ? overlays then
      inputs.mcps.overlays.default
    else
      (_final: _prev: { });

  # ComfyUI overlay (native Nix package, replaces Docker container)
  comfyui =
    if inputs ? comfyui && inputs.comfyui ? overlays && inputs.comfyui.overlays ? default then
      inputs.comfyui.overlays.default
    else if inputs ? comfyui && inputs.comfyui ? packages && inputs.comfyui.packages ? ${system} then
      (_final: _prev: { comfyui = inputs.comfyui.packages.${system}.default or _prev.hello; })
    else
      (_final: _prev: { });

  # Claude Code overlay (pre-built binaries from Anthropic)
  claude-code-overlay =
    if inputs ? claude-code-overlay && inputs.claude-code-overlay ? overlays then
      inputs.claude-code-overlay.overlays.default
    else
      (_final: _prev: { });

  # Gemini CLI overlay (build from latest GitHub source)
  # Overrides nixpkgs gemini-cli with latest version from GitHub
  # Note: On first build, nix will error with the correct npmDepsHash value
  # Update npmDepsHash with the value nix provides
  gemini-cli-latest = _final: prev: {
    gemini-cli = prev.buildNpmPackage rec {
      pname = "gemini-cli";
      version = "0.19.0-nightly.20251123.dadd606c0";

      src = prev.fetchFromGitHub {
        owner = "google-gemini";
        repo = "gemini-cli";
        rev = "v${version}";
        hash = "sha256-/qI4uixD5ufldTOV6nUXnuUPVBHNhzya1YZ+7RiKoSQ=";
      };

      # npmDepsHash: On first build, nix will provide the correct hash in the error message
      # Update this value after the first build attempt
      npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

      passthru = {
        updateScript = prev.writeShellScript "update-gemini-cli" ''
          set -euo pipefail

          # Get the directory where this overlay file is located
          OVERLAY_DIR="$(cd "$(dirname "${BASH_SOURCE [ 0 ]}")" && pwd)"
          OVERLAY_FILE="$OVERLAY_DIR/overlays/default.nix"

          # Get latest version from GitHub API
          echo "Fetching latest gemini-cli version..."
          LATEST_TAG=$(curl -s https://api.github.com/repos/google-gemini/gemini-cli/releases/latest | \
            ${prev.jq}/bin/jq -r '.tag_name' | sed 's/^v//')

          if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" = "null" ]; then
            echo "Error: Could not fetch latest version"
            exit 1
          fi

          echo "Latest version: $LATEST_TAG"

          # Get current version from overlay
          CURRENT_VERSION=$(grep -oP 'version = "\K[^"]+' "$OVERLAY_FILE" | head -1)

          if [ "$CURRENT_VERSION" = "$LATEST_TAG" ]; then
            echo "Already at latest version: $LATEST_TAG"
            exit 0
          fi

          # Get new hash
          echo "Fetching hash for version $LATEST_TAG..."
          NEW_HASH=$(${prev.nix-prefetch-github}/bin/nix-prefetch-github \
            google-gemini gemini-cli \
            --rev "v$LATEST_TAG" 2>/dev/null | \
            ${prev.jq}/bin/jq -r '.hash')

          if [ -z "$NEW_HASH" ] || [ "$NEW_HASH" = "null" ]; then
            echo "Error: Could not fetch hash"
            exit 1
          fi

          echo "New hash: $NEW_HASH"

          # Update overlay file
          ${prev.gnused}/bin/sed -i "s/version = \".*\";/version = \"$LATEST_TAG\";/" "$OVERLAY_FILE"
          ${prev.gnused}/bin/sed -i "s|rev = \".*\";|rev = \"v$LATEST_TAG\";|" "$OVERLAY_FILE"
          ${prev.gnused}/bin/sed -i "s|hash = \".*\";|hash = \"$NEW_HASH\";|" "$OVERLAY_FILE"

          echo "✅ Updated gemini-cli from $CURRENT_VERSION to $LATEST_TAG"
          echo "⚠️  Note: npmDepsHash will need to be updated after building"
          echo "   Run: nix build .#gemini-cli-latest.gemini-cli"
          echo "   Then update npmDepsHash with the value from the error message"
        '';
      };

      meta = with prev.lib; {
        description = "Official CLI for Google Gemini API (latest from GitHub)";
        homepage = "https://github.com/google-gemini/gemini-cli";
        license = licenses.asl20;
        maintainers = [ ];
      };
    };
  };
}
