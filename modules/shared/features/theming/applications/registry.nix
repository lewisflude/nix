{ lib }:
rec {
  # Application metadata structure
  # Each application entry contains information about the application module
  applications = {
    # Editors
    cursor = {
      name = "cursor";
      displayName = "Cursor/VS Code";
      platform = "home"; # home, nixos, or both
      category = "editor";
      description = "Code editor (Cursor/VS Code theme)";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/editors/cursor.nix";
    };

    # helix - now provided by Signal flake

    zed = {
      name = "zed";
      displayName = "Zed Editor";
      platform = "home";
      category = "editor";
      description = "Zed editor theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/editors/zed.nix";
    };

    # Terminals
    # ghostty - now provided by Signal flake
    # zellij - now provided by Signal flake

    # Desktop (Wayland/Linux)
    # fuzzel - now provided by Signal flake

    ironbar = {
      name = "ironbar";
      displayName = "Ironbar";
      platform = "both"; # Available in both NixOS and Home Manager
      category = "desktop";
      description = "Ironbar status bar theme";
      dependencies = [ ];
      modulePathNixOS = "modules/shared/features/theming/applications/desktop/ironbar-nixos.nix";
      modulePathHome = "modules/shared/features/theming/applications/desktop/ironbar-home.nix";
    };

    mako = {
      name = "mako";
      displayName = "Mako";
      platform = "nixos";
      category = "desktop";
      description = "Mako notification daemon theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/desktop/mako.nix";
    };

    swaync = {
      name = "swaync";
      displayName = "SwayNC";
      platform = "nixos";
      category = "desktop";
      description = "SwayNC notification center theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/desktop/swaync.nix";
    };

    satty = {
      name = "satty";
      displayName = "Satty";
      platform = "home";
      category = "desktop";
      description = "Satty screenshot annotation tool theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/desktop/satty.nix";
    };

    # gtk - now provided by Signal flake

    # CLI Tools
    # bat - now provided by Signal flake
    # fzf - now provided by Signal flake
    # lazygit - now provided by Signal flake
    # yazi - now provided by Signal flake
  };

  # Query functions
  getByPlatform =
    platform: lib.filterAttrs (_: app: app.platform == platform || app.platform == "both") applications;

  getByCategory = category: lib.filterAttrs (_: app: app.category == category) applications;

  getAll = applications;

  getByName = name: applications.${name} or null;

  # Get all applications for a platform, grouped by category
  getByPlatformGrouped =
    platform:
    let
      platformApps = getByPlatform platform;
      categories = [
        "editor"
        "terminal"
        "desktop"
        "cli"
      ];
    in
    lib.genAttrs categories (category: lib.filterAttrs (_: app: app.category == category) platformApps);
}
