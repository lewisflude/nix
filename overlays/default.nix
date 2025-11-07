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

  # Helper: Fenix overlay with cache optimization workaround
  # See fenix issue #79: Use fenix's nixpkgs for cache compatibility
  mkFenixOverlay =
    _final: _prev:
    let
      pkgs = inputs.fenix.inputs.nixpkgs.legacyPackages.${system};
    in
    inputs.fenix.overlays.default pkgs pkgs;

  overlaySet = {
    localPkgs = _final: prev: {
      cursor = prev.callPackage (../pkgs + "/cursor") { };
    };

    npm-packages = import ./npm-packages.nix;

    ironbar-fix = mkOptionalOverlay isLinux (import ./ironbar.nix);

    nh = mkOptionalOverlay (inputs ? nh && inputs.nh ? overlays) inputs.nh.overlays.default;

    nix-topology = mkOptionalOverlay (
      inputs ? nix-topology && inputs.nix-topology ? overlays
    ) inputs.nix-topology.overlays.default;

    flake-editors = _final: _prev: { };

    fenix-overlay = mkOptionalOverlay (inputs ? fenix && inputs.fenix ? overlays) mkFenixOverlay;

    flake-git-tools = mkFlakePackage "lazygit" "lazygit" (prev: prev.lazygit);

    flake-cli-tools = mkFlakePackage "atuin" "atuin" (prev: prev.atuin);

    niri = mkOptionalOverlay (
      isLinux && inputs ? niri && inputs.niri ? overlays
    ) inputs.niri.overlays.niri;

    # Removed chaotic-packages overlay - using nyx-overlay module instead
    # This allows packages to use stable (cached) versions by default
    # If you need _git versions, use them explicitly (e.g., pkgs.pipewire_git)
    # chaotic-packages = mkOptionalOverlay (isLinux && inputs ? chaotic) (import ./chaotic-packages.nix);
  };
in
overlaySet
