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
      fenix-overlay =
        if inputs ? fenix && inputs.fenix ? overlays then inputs.fenix.overlays.default else noopOverlay;

      # Niri compositor (Linux only)
      niri =
        if isLinux && inputs ? niri && inputs.niri ? overlays then
          inputs.niri.overlays.niri
        else
          noopOverlay;

      # ComfyUI overlay (native Nix package, replaces Docker container)
      comfyui =
        if inputs ? comfyui && inputs.comfyui ? overlays && inputs.comfyui.overlays ? default then
          inputs.comfyui.overlays.default
        else if inputs ? comfyui && inputs.comfyui ? packages && inputs.comfyui.packages ? ${system} then
          (_final: _prev: { comfyui = inputs.comfyui.packages.${system}.default or _prev.hello; })
        else
          noopOverlay;

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
          noopOverlay;

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

      # yutu - YouTube MCP server
      yutu = _final: prev: {
        yutu = prev.callPackage ../pkgs/yutu.nix { };
      };

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
      nur = if inputs ? nur && inputs.nur ? overlays then inputs.nur.overlays.default else noopOverlay;

      # Wayland packages (Linux only)
      nixpkgs-wayland =
        if isLinux && inputs ? nixpkgs-wayland && inputs.nixpkgs-wayland ? overlay then
          inputs.nixpkgs-wayland.overlay
        else
          noopOverlay;

      # Blender upstream binary (avoids LLVM version conflict between CUDA and Mesa)
      blender-bin =
        if isLinux && inputs ? nix-warez && inputs.nix-warez ? overlays then
          inputs.nix-warez.overlays.default
        else
          noopOverlay;

      # WiVRn with CUDA encoding support (64-bit only)
      # OpenVR compatibility paths managed by WiVRn itself since v0.23
      wivrn-cuda =
        if isLinux then
          final: prev:
          if prev.stdenv.hostPlatform.system == "x86_64-linux" then
            {
              wivrn = prev.wivrn.override {
                cudaSupport = true;
                inherit (final) cudaPackages;
              };
            }
          else
            { }
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
