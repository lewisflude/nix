# Overlay definitions
# Dendritic pattern: Exposes overlaysForSystem as a top-level option
{ lib, inputs, ... }:
let
  mkOverlaySet =
    system:
    let
      isLinux = lib.hasSuffix "-linux" system;
      noopOverlay = _final: _prev: { };
    in
    {
      # Rust toolchains from fenix (better than nixpkgs)
      fenix-overlay = inputs.fenix.overlays.default;

      # Niri compositor (Linux only)
      niri = if isLinux then inputs.niri.overlays.niri else noopOverlay;

      # ComfyUI overlay: upstream exposes either overlays.default or packages.<system>.default
      comfyui =
        if inputs.comfyui ? overlays && inputs.comfyui.overlays ? default then
          inputs.comfyui.overlays.default
        else if inputs.comfyui.packages ? ${system} then
          (_final: _prev: { comfyui = inputs.comfyui.packages.${system}.default; })
        else
          noopOverlay;

      # Audio.nix overlay (Bitwig Studio and audio plugins, Linux only)
      audio-nix =
        if isLinux then
          final: super:
          let
            superWithWebkit =
              super // (if super ? webkitgtk_6_0 then { webkitgtk = super.webkitgtk_6_0; } else { });
          in
          inputs.audio-nix.overlays.default final superWithWebkit
        else
          noopOverlay;

      # LLM agents
      llm-agents =
        _final: _prev:
        let
          llmAgentPkgs = inputs.llm-agents.packages.${system} or { };
        in
        {
          llmAgents = llmAgentPkgs;
        }
        // (if llmAgentPkgs ? gemini-cli then { inherit (llmAgentPkgs) gemini-cli; } else { });

      # Claude Code from sadjow/claude-code-nix (hourly upstream updates, Cachix cache)
      # Takes precedence over the llm-agents variant because composeExtensions applies
      # later overlays last, and "n" (naming below) sorts after "l" (llm-agents).
      native-claude-code =
        _final: _prev:
        let
          pkgs = inputs.claude-code-nix.packages.${system} or null;
        in
        if pkgs != null then { claude-code = pkgs.default; } else { };

      # GCC 15 ICE workarounds for i686-linux (Steam FHS env needs these)
      # Lowers optimization to -O1 or disables tests for packages that trigger compiler bugs
      i686-test-fixes =
        _final: prev:
        if prev.stdenv.hostPlatform.system == "i686-linux" then
          let
            lowerOptLevel =
              pkg:
              pkg.overrideAttrs (old: {
                env = (old.env or { }) // {
                  NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "") + " -O1";
                };
              });
            skipTests = pkg: pkg.overrideAttrs { doCheck = false; };
            skipAllTests =
              pkg:
              pkg.overrideAttrs {
                doCheck = false;
                doInstallCheck = false;
              };
          in
          {
            onetbb = skipTests prev.onetbb;
            flac = skipTests prev.flac;
            ffmpeg-headless = skipTests prev.ffmpeg-headless;
            libpulseaudio = skipTests prev.libpulseaudio;
            git = lowerOptLevel (skipAllTests prev.git);
            gitMinimal = lowerOptLevel (skipAllTests prev.gitMinimal);
            cargo = lowerOptLevel prev.cargo;
            sane-backends = lowerOptLevel prev.sane-backends;
            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
              (_python-final: python-prev: {
                pycairo = python-prev.pycairo.overridePythonAttrs { doCheck = false; };
                filelock = python-prev.filelock.overridePythonAttrs { doCheck = false; };
                distutils = python-prev.distutils.overridePythonAttrs { doCheck = false; };
                hypothesis = python-prev.hypothesis.overridePythonAttrs { doCheck = false; };
              })
            ];
          }
        else
          { };

      # Java 25 for Hytale
      java25 =
        final: prev:
        let
          jdk25 =
            prev.temurin_25_jdk or (prev.jdk25 or (prev.openjdk25 or (builtins.trace ''
              WARNING: Java 25 not found in nixpkgs, falling back to JDK ${prev.jdk.version}
            '' prev.jdk)
            )
            );
        in
        {
          inherit jdk25;
          java25 = jdk25;
        };

      # Danksearch
      danksearch =
        _final: _prev:
        let
          pkgs = inputs.danksearch.packages.${system} or null;
        in
        if pkgs != null then { danksearch = pkgs.default; } else { };

      # Claude Desktop (Linux only, patched: nodePackages.asar removed from nixpkgs 2026-03-03)
      claude-desktop =
        final: prev:
        if isLinux then
          let
            src = inputs.claude-desktop-linux;
            patchy-cnb = prev.callPackage "${src}/pkgs/patchy-cnb.nix" { };
            claude-desktop-unwrapped = prev.callPackage "${src}/pkgs/claude-desktop.nix" {
              inherit patchy-cnb;
              nodePackages = {
                inherit (final) asar;
              };
            };
          in
          {
            claude-desktop = prev.buildFHSEnv {
              name = "claude-desktop";
              targetPkgs = p: [
                p.docker
                p.glibc
                p.openssl
                p.nodejs
                p.uv
              ];
              runScript = "${claude-desktop-unwrapped}/bin/claude-desktop";
              extraInstallCommands = ''
                mkdir -p $out/share/applications
                cp ${claude-desktop-unwrapped}/share/applications/claude.desktop $out/share/applications/
                mkdir -p $out/share/icons
                cp -r ${claude-desktop-unwrapped}/share/icons/* $out/share/icons/
              '';
            };
          }
        else
          { };

      # cli-helpers 2.10.0: three test_style_output tests assert hardcoded ANSI
      # escapes that newer Pygments resolves differently (bg:#eee -> 255 not 7).
      # Remove once nixpkgs PR #493910 (bump to 2.14.0) lands.
      cli-helpers-fix = _final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (_python-final: python-prev: {
            cli-helpers = python-prev.cli-helpers.overridePythonAttrs (old: {
              disabledTests = (old.disabledTests or [ ]) ++ [
                "test_style_output"
                "test_style_output_with_newlines"
                "test_style_output_custom_tokens"
              ];
            });
          })
        ];
      };

      # khal: sphinxcontrib-newsfeed is broken with Sphinx 9.x
      # Skip docs build entirely until upstream fixes it
      khal-fix = _final: prev: {
        khal = prev.khal.overrideAttrs (old: {
          nativeBuildInputs = builtins.filter (d: !lib.hasInfix "sphinx" (d.name or "")) (
            old.nativeBuildInputs or [ ]
          );
          outputs = [
            "out"
            "dist"
          ];
        });
      };

      # NUR
      nur = inputs.nur.overlays.default;

      # OpenClaw (upstream nix-openclaw flake): replaces pkgs.openclaw with the
      # version the home-manager module expects and adds openclaw-gateway etc.
      nix-openclaw = inputs.nix-openclaw.overlays.default;

      # WiVRn with CUDA encoding support (x86_64-linux only)
      # OpenVR compatibility paths managed by WiVRn itself since v0.23
      wivrn-cuda =
        if system == "x86_64-linux" then
          final: prev: {
            wivrn = prev.wivrn.override {
              cudaSupport = true;
              inherit (final) cudaPackages;
            };
          }
        else
          noopOverlay;
    };
in
{
  options.overlaysForSystem = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = system: builtins.attrValues (mkOverlaySet system);
    description = "Function: system -> [overlay] returning all configured overlays";
  };

  config.flake.overlays.default =
    final: prev:
    if !(prev ? stdenv) then
      { } # nix flake check calls overlay {} {} — noop without real nixpkgs
    else
      let
        inherit (prev.stdenv.hostPlatform) system;
        overlayList = builtins.attrValues (mkOverlaySet system);
      in
      (lib.foldl' lib.composeExtensions (_: _: { }) overlayList) final prev;
}
