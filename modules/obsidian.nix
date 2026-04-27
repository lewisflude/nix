# Obsidian configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.obsidian
# Cross-platform: home-manager module handles Linux (XDG) and Darwin paths.
#
# Selective declarative scope: only settings worth syncing across machines are
# locked here. Plugins, themes and editor toggles are left to the Obsidian UI
# because the home-manager module turns every declared JSON file into a
# read-only nix-store symlink (see home-manager#7906).
_: {
  flake.modules.homeManager.obsidian =
    { pkgs, ... }:
    {
      programs.obsidian = {
        enable = true;
        package = pkgs.obsidian;
        cli.enable = true;

        defaultSettings = {
          app = {
            attachmentFolderPath = "Attachments";
            alwaysUpdateLinks = true;
            newLinkFormat = "shortest";
            promptDelete = false;
          };

          appearance = {
            baseFontSize = 16;
            interfaceFontFamily = "Iosevka";
            textFontFamily = "Iosevka";
            monospaceFontFamily = "Iosevka";
          };
        };

        vaults."Obsidian Vault" = {
          enable = true;
          target = "Obsidian Vault";
        };
      };
    };
}
