{
  inputs,
  system,
}:
let
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";

  overlaySet = {

    localPkgs =
      _final: prev:
      let
        pkgsDir = ../pkgs;

        usedPackages = {
          cursor = prev.callPackage (pkgsDir + "/cursor") { };

        };
      in
      usedPackages;

    npm-packages = import ./npm-packages.nix;

    nh =
      if inputs ? nh && inputs.nh ? overlays then inputs.nh.overlays.default else (_final: _prev: { });

    nix-topology =
      if inputs ? nix-topology && inputs.nix-topology ? overlays then
        inputs.nix-topology.overlays.default
      else
        (_final: _prev: { });

    flake-editors = _final: _prev: {

    };

    fenix-overlay =
      if inputs ? fenix && inputs.fenix ? overlays then
        # Cache optimization workaround (see fenix issue #79):
        # Use fenix's nixpkgs instead of the system's nixpkgs to ensure cache compatibility.
        # This is critical for cache hits because:
        # 1. Fenix packages are built against fenix's nixpkgs version
        # 2. Using system nixpkgs can cause cache misses if versions differ
        # 3. nix-community.cachix.org has packages built with fenix's nixpkgs
        # This ensures maximum cache utilization and fastest builds.
        (
          _: _:
          let
            pkgs = inputs.fenix.inputs.nixpkgs.legacyPackages.${system};
          in
          inputs.fenix.overlays.default pkgs pkgs
        )
      else
        (_final: _prev: { });

    flake-git-tools = _final: prev: {
      lazygit =
        if
          inputs ? lazygit
          && inputs.lazygit ? packages
          && inputs.lazygit.packages ? ${system}
          && inputs.lazygit.packages.${system} ? default
        then
          inputs.lazygit.packages.${system}.default
        else
          prev.lazygit;
    };

    flake-cli-tools = _final: prev: {
      atuin =
        if
          inputs ? atuin
          && inputs.atuin ? packages
          && inputs.atuin.packages ? ${system}
          && inputs.atuin.packages.${system} ? default
        then
          inputs.atuin.packages.${system}.default
        else
          prev.atuin;
    };

    niri =
      if isLinux && inputs ? niri && inputs.niri ? overlays then
        inputs.niri.overlays.niri
      else
        (_final: _prev: { });

    chaotic-packages =
      if isLinux && inputs ? chaotic then import ./chaotic-packages.nix else (_final: _prev: { });
  };
in
overlaySet
