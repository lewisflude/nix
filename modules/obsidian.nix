# Obsidian configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.obsidian
# Cross-platform: home-manager module handles Linux (XDG) and Darwin paths.
#
# Selective declarative scope: only settings worth syncing across machines are
# locked here. Plugins, themes and editor toggles are left to the Obsidian UI
# because the home-manager module turns every declared JSON file into a
# read-only nix-store symlink (see home-manager#7906).
#
# Sync: extends flake.modules.{nixos,homeManager}.syncthing with the vault
# folder and peer device entries. Activates only once both syncthing IDs in
# constants.hosts.* are populated.
{ config, lib, ... }:
let
  inherit (config) username;
  inherit (config.constants) hosts;

  vaultName = "obsidian-vault";
  vaultLabel = "Obsidian Vault";

  bothConfigured = hosts.jupiter.syncthingId != "" && hosts.mercury.syncthingId != "";

  versioning = {
    type = "simple";
    params.keep = "10";
  };
in
{
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
          target = vaultLabel;
        };
      };
    };

  # Jupiter side: NixOS system service contribution.
  flake.modules.nixos.syncthing = lib.mkIf bothConfigured (_: {
    services.syncthing.settings = {
      devices.mercury = {
        id = hosts.mercury.syncthingId;
        addresses = [ "tcp://${hosts.mercury.tailscaleIpv4}:22000" ];
      };
      folders.${vaultName} = {
        label = vaultLabel;
        path = "/home/${username}/${vaultLabel}";
        devices = [ "mercury" ];
        inherit versioning;
      };
    };
  });

  # Mercury side (and any other home-manager peer): user-scope contribution.
  flake.modules.homeManager.syncthing = lib.mkIf bothConfigured (
    { config, ... }:
    {
      services.syncthing.settings = {
        devices.jupiter = {
          id = hosts.jupiter.syncthingId;
          addresses = [ "tcp://${hosts.jupiter.tailscaleIpv4}:22000" ];
        };
        folders.${vaultName} = {
          label = vaultLabel;
          path = "${config.home.homeDirectory}/${vaultLabel}";
          devices = [ "jupiter" ];
          inherit versioning;
        };
      };
    }
  );
}
