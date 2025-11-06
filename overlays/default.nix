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

    rust-overlay =
      if inputs ? rust-overlay && inputs.rust-overlay ? overlays then
        inputs.rust-overlay.overlays.default
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
