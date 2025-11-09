{ lib }:
let
  inherit (lib) types;
in
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

    helix = {
      name = "helix";
      displayName = "Helix Editor";
      platform = "home";
      category = "editor";
      description = "Helix editor theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/editors/helix.nix";
    };

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
    ghostty = {
      name = "ghostty";
      displayName = "Ghostty Terminal";
      platform = "home";
      category = "terminal";
      description = "Ghostty terminal ANSI colors";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/terminals/ghostty.nix";
    };

    zellij = {
      name = "zellij";
      displayName = "Zellij";
      platform = "home";
      category = "terminal";
      description = "Zellij terminal multiplexer theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/terminals/zellij.nix";
    };

    # Desktop (Wayland/Linux)
    fuzzel = {
      name = "fuzzel";
      displayName = "Fuzzel";
      platform = "nixos";
      category = "desktop";
      description = "Fuzzel application launcher theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/desktop/fuzzel.nix";
    };

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

    swappy = {
      name = "swappy";
      displayName = "Swappy";
      platform = "nixos";
      category = "desktop";
      description = "Swappy screenshot annotation tool theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/desktop/swappy.nix";
    };

    gtk = {
      name = "gtk";
      displayName = "GTK";
      platform = "home";
      category = "desktop";
      description = "GTK3/GTK4 application theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/desktop/gtk.nix";
    };

    # CLI Tools
    bat = {
      name = "bat";
      displayName = "bat";
      platform = "home";
      category = "cli";
      description = "bat syntax highlighter theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/cli/bat.nix";
    };

    fzf = {
      name = "fzf";
      displayName = "fzf";
      platform = "home";
      category = "cli";
      description = "fzf fuzzy finder theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/cli/fzf.nix";
    };

    lazygit = {
      name = "lazygit";
      displayName = "lazygit";
      platform = "home";
      category = "cli";
      description = "lazygit Git TUI theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/cli/lazygit.nix";
    };

    yazi = {
      name = "yazi";
      displayName = "yazi";
      platform = "home";
      category = "cli";
      description = "yazi file manager theme";
      dependencies = [ ];
      modulePath = "modules/shared/features/theming/applications/cli/yazi.nix";
    };
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
