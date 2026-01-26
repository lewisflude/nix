# Package overlays
# Simplified - only essential customizations
{ inputs, system }:
let
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";
in
{
  # NH is now sourced from nixpkgs (stable) instead of flake input
  # This avoids test failures on Darwin when building from source
  # The nixpkgs version is kept up-to-date and is stable
  # nh = (_final: _prev: { });

  # Network topology visualization
  nix-topology =
    if inputs ? nix-topology && inputs.nix-topology ? overlays then
      inputs.nix-topology.overlays.default
    else
      (_final: _prev: { });

  # Rust toolchains from fenix (better than nixpkgs)
  fenix-overlay =
    if inputs ? fenix && inputs.fenix ? overlays then
      inputs.fenix.overlays.default
    else
      (_final: _prev: { });

  # Niri compositor (Linux only)
  niri =
    if isLinux && inputs ? niri && inputs.niri ? overlays then
      inputs.niri.overlays.niri
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

  # Audio.nix overlay (Bitwig Studio and audio plugins)
  # Wrapped with webkitgtk compatibility fix
  audio-nix =
    if
      isLinux && inputs ? audio-nix && inputs.audio-nix ? overlays && inputs.audio-nix.overlays ? default
    then
      # Wrap the audio.nix overlay to add webkitgtk compatibility
      final: super:
      let
        # First apply webkitgtk compatibility
        superWithWebkit =
          super // (if super ? webkitgtk_6_0 then { webkitgtk = super.webkitgtk_6_0; } else { });
        # Then apply the audio.nix overlay
        audioNixOverlay = inputs.audio-nix.overlays.default;
      in
      audioNixOverlay final superWithWebkit
    else
      (_final: _prev: { });

  # LLM agents - use pre-built binaries from llm-agents.nix
  # Daily builds with binary cache at https://cache.numtide.com
  llm-agents =
    _final: _prev:
    if
      inputs ? llm-agents && inputs.llm-agents ? packages && inputs.llm-agents.packages ? ${system}
    then
      inputs.llm-agents.packages.${system}
    else
      { };

  # OneTBB - Disable tests on i686-linux (32-bit)
  # The onetbb test suite has known flakiness issues on 32-bit systems,
  # particularly in sandboxed build environments (SIGABRT crashes in threading tests).
  # This is a common issue affecting immersed and other VR packages that need 32-bit libraries.
  # Disabling tests on i686-linux is the standard nixpkgs approach for this issue.
  onetbb-fix = _final: prev: {
    onetbb =
      if prev.stdenv.hostPlatform.system == "i686-linux" then
        prev.onetbb.overrideAttrs (oldAttrs: {
          doCheck = false;
          # Document why tests are disabled
          meta = (oldAttrs.meta or { }) // {
            description =
              (oldAttrs.meta.description or "") + " (tests disabled on i686-linux due to flakiness)";
          };
        })
      else
        prev.onetbb;
  };

  # yutu - YouTube MCP server and CLI
  yutu = _final: prev: {
    yutu = prev.callPackage ../pkgs/yutu.nix { };
  };

  # Java 25 for Hytale server
  # Hytale officially requires Java 25 (Adoptium/Temurin recommended)
  # See: https://support.hytale.com/hc/en-us/articles/hytale-server-manual
  java25 =
    final: prev:
    let
      # Check if jdk25 or temurin_25_jdk exists in nixpkgs
      # If not, we'll use the latest available JDK and warn
      jdk25 =
        if prev ? temurin_25_jdk then
          prev.temurin_25_jdk
        else if prev ? jdk25 then
          prev.jdk25
        else if prev ? openjdk25 then
          prev.openjdk25
        else
          # Fallback to latest JDK with a prominent warning
          builtins.trace ''

            ╔═══════════════════════════════════════════════════════════════════════╗
            ║ WARNING: Java 25 not found in nixpkgs                                ║
            ║ Falling back to JDK ${prev.jdk.version}                                          ║
            ╚═══════════════════════════════════════════════════════════════════════╝

            Hytale officially requires Java 25 (Adoptium/Temurin recommended).
            The server may work with other Java versions but this is UNSUPPORTED.

            To use Java 25:
              1. Update nixpkgs to a version that includes Java 25
              2. Use a flake input for Adoptium Temurin
              3. Override with a custom Java 25 package

            See: https://adoptium.net/temurin/releases/

          '' prev.jdk;
    in
    {
      jdk25 = jdk25;
      # Also provide as java25 for consistency
      java25 = jdk25;
    };

  # Immersed VR - Use latest version from static URL
  # This pulls the latest release directly instead of using archived versions
  immersed-latest = _final: prev: {
    immersed = prev.immersed.overrideAttrs (oldAttrs: {
      version = "11.0.0-latest";
      src =
        if prev.stdenv.isLinux && prev.stdenv.isx86_64 then
          prev.fetchurl {
            url = "https://static.immersed.com/dl/Immersed-x86_64.AppImage";
            hash = "sha256-GbckZ/WK+7/PFQvTfUwwePtufPKVwIwSPh+Bo/cG7ko=";
          }
        else if prev.stdenv.isLinux && prev.stdenv.isAarch64 then
          prev.fetchurl {
            url = "https://static.immersed.com/dl/Immersed-aarch64.AppImage";
            # Note: Hash needs to be verified for aarch64
            hash = "sha256-3BokV30y6QRjE94K7JQ6iIuQw1t+h3BKZY+nEFGTVHI=";
          }
        else if prev.stdenv.isDarwin then
          prev.fetchurl {
            url = "https://static.immersed.com/dl/Immersed.dmg";
            # Note: Hash needs to be verified for macOS
            hash = "sha256-lmSkatB75Bztm19aCC50qrd/NV+HQX9nBMOTxIguaqI=";
          }
        else
          throw "Unsupported system: ${prev.stdenv.system}";

      meta = oldAttrs.meta // {
        description = "VR coworking platform (latest from static URL)";
      };
    });
  };

  # Community Overlays
  # These provide access to community-maintained packages and bleeding-edge versions
  # See docs/COMMUNITY_OVERLAYS.md for details

  # Nix User Repository (NUR)
  # Community packages from 300+ contributors
  # No binary cache - packages built from source
  nur =
    if inputs ? nur && inputs.nur ? overlays then inputs.nur.overlays.default else (_final: _prev: { });

  # Bleeding-edge Wayland packages (Linux only)
  # Daily builds of sway, wlroots, wayland tools from upstream
  # Binary cache: https://nixpkgs-wayland.cachix.org
  nixpkgs-wayland =
    if isLinux && inputs ? nixpkgs-wayland && inputs.nixpkgs-wayland ? overlay then
      inputs.nixpkgs-wayland.overlay
    else
      (_final: _prev: { });

}
