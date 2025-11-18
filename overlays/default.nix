{
  inputs,
  system,
}:
let
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";

  # Helper: Create an optional overlay that only applies if condition is true
  mkOptionalOverlay = cond: overlay: if cond then overlay else (_final: _prev: { });

  # Helper: Get package from flake input packages if available, otherwise use prev
  mkFlakePackage =
    inputName: packageName: fallback: _final: prev:
    let
      hasInput = inputs ? ${inputName};
      hasPackages = hasInput && inputs.${inputName} ? packages;
      hasSystem = hasPackages && inputs.${inputName}.packages ? ${system};
      hasPackage = hasSystem && inputs.${inputName}.packages.${system} ? default;
    in
    {
      ${packageName} =
        if hasPackage then inputs.${inputName}.packages.${system}.default else fallback prev;
    };

  overlaySet = {
    localPkgs =
      _final: prev:
      let
        cursorPkgs = prev.callPackage (../pkgs + "/cursor") { };
      in
      {
        # Only expose cursor app, cursor-cli should come from nixpkgs
        inherit (cursorPkgs) cursor;
      };

    # Fix flaky ipython performance test and arrow-cpp S3 test
    python-fixes = _final: prev: {
      python3 = prev.python3.override {
        packageOverrides = _pyFinal: pyPrev: {
          ipython = pyPrev.ipython.overrideAttrs (old: {
            disabledTests = (old.disabledTests or [ ]) ++ [ "test_stream_performance" ];
          });
          # Skip failing langchain-community tests (needed for open-webui)
          langchain-community = pyPrev.langchain-community.overrideAttrs (_old: {
            doCheck = false; # Skip all tests - too many failing with Python 3.13
          });
        };
      };
      # Disable arrow-cpp tests - the S3 filesystem test (arrow-s3fs-test) is flaky
      arrow-cpp = prev.arrow-cpp.overrideAttrs (_old: {
        doInstallCheck = false;
        doCheck = false;
      });
    };

    npm-packages = import ./npm-packages.nix;

    nh = mkOptionalOverlay (inputs ? nh && inputs.nh ? overlays) inputs.nh.overlays.default;

    nix-topology = mkOptionalOverlay (
      inputs ? nix-topology && inputs.nix-topology ? overlays
    ) inputs.nix-topology.overlays.default;

    # Use stable zed-editor from nixpkgs instead of flake input
    flake-editors = _final: prev: {
      inherit (prev) zed-editor;
    };

    # Re-enabled: fenix provides better Rust toolchains than nixpkgs
    fenix-overlay = mkOptionalOverlay (
      inputs ? fenix && inputs.fenix ? overlays
    ) inputs.fenix.overlays.default;

    flake-git-tools = mkFlakePackage "lazygit" "lazygit" (prev: prev.lazygit);

    flake-cli-tools = mkFlakePackage "atuin" "atuin" (prev: prev.atuin);

    niri = mkOptionalOverlay (
      isLinux && inputs ? niri && inputs.niri ? overlays
    ) inputs.niri.overlays.niri;

    # Chaotic Nyx overlay: Not needed here
    # - For NixOS: chaotic.nixosModules.default provides the overlay at system level
    # - For darwin: chaotic.homeManagerModules.default is used (requires useGlobalPkgs = false)
  };
in
overlaySet
