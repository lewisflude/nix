# Shared internal values
# This file is imported by other modules to access common functions and overlays
# NOT a flake-parts module - just a plain Nix file returning an attrset
{ lib, inputs }:
let
  # Library functions
  myLib = {
    # Platform detection
    isLinux = system: lib.hasSuffix "-linux" system;
    isDarwin = system: lib.hasSuffix "-darwin" system;

    # Cross-platform path helpers
    homeDir =
      system: username:
      if lib.hasSuffix "-darwin" system then "/Users/${username}" else "/home/${username}";
    configDir =
      system: username:
      let
        homeDir = if lib.hasSuffix "-darwin" system then "/Users/${username}" else "/home/${username}";
      in
      "${homeDir}/.config";
    dataDir =
      system: username:
      let
        homeDir = if lib.hasSuffix "-darwin" system then "/Users/${username}" else "/home/${username}";
      in
      if lib.hasSuffix "-darwin" system then
        "${homeDir}/Library/Application Support"
      else
        "${homeDir}/.local/share";
    cacheDir =
      system: username:
      let
        homeDir = if lib.hasSuffix "-darwin" system then "/Users/${username}" else "/home/${username}";
      in
      if lib.hasSuffix "-darwin" system then "${homeDir}/Library/Caches" else "${homeDir}/.cache";

    # Package selection helpers
    platformPackage =
      system: linuxPkg: darwinPkg:
      if lib.hasSuffix "-darwin" system then darwinPkg else linuxPkg;
    platformPackages =
      system: linuxPkgs: darwinPkgs:
      if lib.hasSuffix "-darwin" system then darwinPkgs else linuxPkgs;

    # Pkgs configuration for nixpkgs import
    mkPkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
      allowBrokenPredicate =
        pkg:
        let
          name = toString (pkg.name or "");
        in
        lib.hasPrefix "zfs-kernel" name || name == "postgresql-test-hook";
      allowUnsupportedSystem = false;
    };

    # Curry system-dependent functions
    withSystem =
      system:
      let
        isDarwin = lib.hasSuffix "-darwin" system;
        homeDir = username: if isDarwin then "/Users/${username}" else "/home/${username}";
      in
      {
        inherit system;
        isLinux = lib.hasSuffix "-linux" system;
        isDarwin = isDarwin;
        homeDir = homeDir;
        configDir = username: "${homeDir username}/.config";
        dataDir =
          username: if isDarwin then "${homeDir username}/Library/Application Support" else "${homeDir username}/.local/share";
        cacheDir = username: if isDarwin then "${homeDir username}/Library/Caches" else "${homeDir username}/.cache";
        platformPackage = linuxPkg: darwinPkg: if isDarwin then darwinPkg else linuxPkg;
        platformPackages = linuxPkgs: darwinPkgs: if isDarwin then darwinPkgs else linuxPkgs;
      };
  };

  # Overlay definitions
  mkOverlaySet =
    system:
    let
      isLinux = system == "x86_64-linux" || system == "aarch64-linux";
    in
    {
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
      audio-nix =
        if
          isLinux && inputs ? audio-nix && inputs.audio-nix ? overlays && inputs.audio-nix.overlays ? default
        then
          final: super:
          let
            superWithWebkit =
              super // (if super ? webkitgtk_6_0 then { webkitgtk = super.webkitgtk_6_0; } else { });
            audioNixOverlay = inputs.audio-nix.overlays.default;
          in
          audioNixOverlay final superWithWebkit
        else
          (_final: _prev: { });

      # LLM agents
      llm-agents =
        _final: _prev:
        let
          llmAgentPkgs =
            if
              inputs ? llm-agents && inputs.llm-agents ? packages && inputs.llm-agents.packages ? ${system}
            then
              inputs.llm-agents.packages.${system}
            else
              { };
        in
        {
          llmAgents = llmAgentPkgs;
          claude-code = llmAgentPkgs.claude-code or _prev.hello;
          gemini-cli = llmAgentPkgs.gemini-cli or _prev.hello;
        };

      # OneTBB fix for i686-linux
      onetbb-fix = _final: prev: {
        onetbb =
          if prev.stdenv.hostPlatform.system == "i686-linux" then
            prev.onetbb.overrideAttrs (oldAttrs: {
              doCheck = false;
              meta = (oldAttrs.meta or { }) // {
                description =
                  (oldAttrs.meta.description or "") + " (tests disabled on i686-linux due to flakiness)";
              };
            })
          else
            prev.onetbb;
      };

      # yutu - YouTube MCP server
      yutu = _final: prev: {
        yutu = prev.callPackage ../pkgs/yutu.nix { };
      };

      # Java 25 for Hytale
      java25 =
        final: prev:
        let
          jdk25 =
            if prev ? temurin_25_jdk then
              prev.temurin_25_jdk
            else if prev ? jdk25 then
              prev.jdk25
            else if prev ? openjdk25 then
              prev.openjdk25
            else
              builtins.trace ''
                WARNING: Java 25 not found in nixpkgs, falling back to JDK ${prev.jdk.version}
              '' prev.jdk;
        in
        {
          jdk25 = jdk25;
          java25 = jdk25;
        };

      # Danksearch
      danksearch =
        _final: _prev:
        if
          inputs ? danksearch && inputs.danksearch ? packages && inputs.danksearch.packages ? ${system}
        then
          { danksearch = inputs.danksearch.packages.${system}.default; }
        else
          { };

      # Awww
      awww =
        _final: _prev:
        if inputs ? awww && inputs.awww ? packages && inputs.awww.packages ? ${system} then
          { awww = inputs.awww.packages.${system}.default; }
        else
          { };

      # NUR
      nur =
        if inputs ? nur && inputs.nur ? overlays then inputs.nur.overlays.default else (_final: _prev: { });

      # Wayland packages (Linux only)
      nixpkgs-wayland =
        if isLinux && inputs ? nixpkgs-wayland && inputs.nixpkgs-wayland ? overlay then
          inputs.nixpkgs-wayland.overlay
        else
          (_final: _prev: { });

      # VR/XR packages (Linux only)
      nixpkgs-xr =
        if isLinux && inputs ? nixpkgs-xr && inputs.nixpkgs-xr ? overlays then
          inputs.nixpkgs-xr.overlays.default
        else
          (_final: _prev: { });
    };

  overlaySet = mkOverlaySet;
  overlaysList = system: builtins.attrValues (mkOverlaySet system);
in
{
  inherit myLib overlaySet overlaysList;
}
